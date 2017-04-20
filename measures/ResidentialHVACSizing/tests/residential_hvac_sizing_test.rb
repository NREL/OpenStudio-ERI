require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessHVACSizingTest < MiniTest::Test

  def beopt_to_os_mapping
    return {
            "DehumidLoad_Inf_Sens"=>["Unit 1 Zone Loads","Dehumid Infil Sens"],
            "DehumidLoad_Inf_Lat"=>["Unit 1 Zone Loads","Dehumid Infil Lat"],
            "DehumidLoad_Int_Sens"=>["Unit 1 Zone Loads","Dehumid IntGains Sens"],
            "DehumidLoad_Int_Lat"=>["Unit 1 Zone Loads","Dehumid IntGains Lat"],
            "Heat Windows"=>["Unit 1 Zone Loads","Heat Windows"],
            "Heat Doors"=>["Unit 1 Zone Loads","Heat Doors"],
            "Heat Walls"=>["Unit 1 Zone Loads","Heat Walls"],
            "Heat Roofs"=>["Unit 1 Zone Loads","Heat Roofs"],
            "Heat Floors"=>["Unit 1 Zone Loads","Heat Floors"],
            "Heat Infil"=>["Unit 1 Zone Loads","Heat Infil"],
            "Dehumid Windows"=>["Unit 1 Zone Loads","Dehumid Windows"],
            "Dehumid Doors"=>["Unit 1 Zone Loads","Dehumid Doors"],
            "Dehumid Walls"=>["Unit 1 Zone Loads","Dehumid Walls"],
            "Dehumid Roofs"=>["Unit 1 Zone Loads","Dehumid Roofs"],
            "Dehumid Floors"=>["Unit 1 Zone Loads","Dehumid Floors"],
            "Cool Windows"=>["Unit 1 Zone Loads","Cool Windows"],
            "Cool Doors"=>["Unit 1 Zone Loads","Cool Doors"],
            "Cool Walls"=>["Unit 1 Zone Loads","Cool Walls"],
            "Cool Roofs"=>["Unit 1 Zone Loads","Cool Roofs"],
            "Cool Floors"=>["Unit 1 Zone Loads","Cool Floors"],
            "Cool Infil Sens"=>["Unit 1 Zone Loads","Cool Infil Sens"],
            "Cool Infil Lat"=>["Unit 1 Zone Loads","Cool Infil Lat"],
            "Cool IntGains Sens"=>["Unit 1 Zone Loads","Cool IntGains Sens"],
            "Cool IntGains Lat"=>["Unit 1 Zone Loads","Cool IntGains Lat"],
            "Heat Load"=>["Unit 1 Initial Results (w/o ducts)","Heat Load"],
            "Cool Load Sens"=>["Unit 1 Initial Results (w/o ducts)","Cool Load Sens"],
            "Cool Load Lat"=>["Unit 1 Initial Results (w/o ducts)","Cool Load Lat"],
            "Dehumid Load Sens"=>["Unit 1 Initial Results (w/o ducts)","Dehumid Load Sens"],
            "Dehumid Load Lat"=>["Unit 1 Initial Results (w/o ducts)","Dehumid Load Lat"],
            "Heat Airflow"=>["Unit 1 Initial Results (w/o ducts)","Heat Airflow"],
            "Cool Airflow"=>["Unit 1 Initial Results (w/o ducts)","Cool Airflow"],
            "HeatingLoad"=>["Unit 1 Final Results","Heat Load"],
            "HeatingDuctLoad"=>["Unit 1 Final Results","Heat Load Ducts"],
            "CoolingLoad_Lat"=>["Unit 1 Final Results","Cool Load Lat"],
            "CoolingLoad_Sens"=>["Unit 1 Final Results","Cool Load Sens"],
            "CoolingLoad_Ducts_Lat"=>["Unit 1 Final Results","Cool Load Ducts Lat"],
            "CoolingLoad_Ducts_Sens"=>["Unit 1 Final Results","Cool Load Ducts Sens"],
            "DehumidLoad_Sens"=>["Unit 1 Final Results","Dehumid Load Sens"],
            "DehumidLoad_Ducts_Lat"=>["Unit 1 Final Results","Dehumid Load Ducts Lat"],
            "Cool_Capacity"=>["Unit 1 Final Results","Cool Capacity"],
            "Cool_SensCap"=>["Unit 1 Final Results","Cool Capacity Sens"],
            "Heat_Capacity"=>["Unit 1 Final Results","Heat Capacity"],
            "SuppHeat_Capacity"=>["Unit 1 Final Results","Heat Capacity Supp"],
            "Cool_AirFlowRate"=>["Unit 1 Final Results","Cool Airflow"],
            "Heat_AirFlowRate"=>["Unit 1 Final Results","Heat Airflow"],
            "Fan_AirFlowRate"=>["Unit 1 Final Results","Fan Airflow"],
            "Dehumid_WaterRemoval_Auto"=>["Unit 1 Final Results","Dehumid WaterRemoval"]
           }
  end
  
  def volume_adj_factor(os_above_grade_finished_volume)
    # TODO: For buildings with finished attic space, BEopt calculates a larger volume 
    # than OpenStudio, so we adjust here. Haven't looked into why this occurs.
    beopt_finished_attic_volume = 2644.625
    os_finished_attic_volume = 2392.6
    living_volume = os_above_grade_finished_volume - os_finished_attic_volume
    return (beopt_finished_attic_volume + living_volume) / (os_finished_attic_volume + living_volume)
  end

  def test_loads_2story_finished_basement_garage_finished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 0,
						'Cool Airflow' => 866,
						'HeatingLoad' => 41587,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_FB_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_loads_2story_finished_basement_garage_finished_attic_ducts_in_fininshed_basement
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 959,
						'HeatingLoad' => 41587,
						'HeatingDuctLoad' => 5818,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 14782,
						'CoolingLoad_Ducts_Lat' => -1761,
						'CoolingLoad_Ducts_Sens' => 3199,
						'DehumidLoad_Sens' => -1829,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 17764,
						'Cool_SensCap' => 11440,
						'Heat_Capacity' => 17764,
						'SuppHeat_Capacity' => 41587,
						'Cool_AirFlowRate' => 738,
						'Heat_AirFlowRate' => 560,
						'Fan_AirFlowRate' => 738,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_FB_GRG_FA_ASHP_DuctsInFB.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_loads_2story_unfinished_basement_garage_finished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1553,
						'DehumidLoad_Inf_Lat' => -1150,
						'DehumidLoad_Int_Sens' => 2232,
						'DehumidLoad_Int_Lat' => 1064,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 9830,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2419,
						'Heat Infil' => 15557,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 1740,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => -269,
						'Cool Infil Sens' => 1911,
						'Cool Infil Lat' => -3140,
						'Cool IntGains Sens' => 2807,
						'Cool IntGains Lat' => 1059,
						'Heat Load' => 38926,
						'Cool Load Sens' => 12687,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -8,
						'Dehumid Load Lat' => -86,
						'Heat Airflow' => 0,
						'Cool Airflow' => 823,
						'HeatingLoad' => 38926,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 12687,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -8,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_UB_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_loads_2story_unfinished_basement_garage_finished_attic_ducts_in_unfinished_basement
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1553,
						'DehumidLoad_Inf_Lat' => -1150,
						'DehumidLoad_Int_Sens' => 2232,
						'DehumidLoad_Int_Lat' => 1064,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 9830,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2419,
						'Heat Infil' => 15557,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 1740,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => -269,
						'Cool Infil Sens' => 1911,
						'Cool Infil Lat' => -3140,
						'Cool IntGains Sens' => 2807,
						'Cool IntGains Lat' => 1059,
						'Heat Load' => 38926,
						'Cool Load Sens' => 12687,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -8,
						'Dehumid Load Lat' => -86,
						'Heat Airflow' => 1227,
						'Cool Airflow' => 884,
						'HeatingLoad' => 46460,
						'HeatingDuctLoad' => 7533,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13618,
						'CoolingLoad_Ducts_Lat' => 1,
						'CoolingLoad_Ducts_Sens' => 928,
						'DehumidLoad_Sens' => -11,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 16366,
						'Cool_SensCap' => 10540,
						'Heat_Capacity' => 16366,
						'SuppHeat_Capacity' => 46460,
						'Cool_AirFlowRate' => 680,
						'Heat_AirFlowRate' => 516,
						'Fan_AirFlowRate' => 680,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_UB_GRG_FA_ASHP_DuctsInUB.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_loads_2story_crawlspace_garage_finished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1553,
						'DehumidLoad_Inf_Lat' => -1150,
						'DehumidLoad_Int_Sens' => 2232,
						'DehumidLoad_Int_Lat' => 1064,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 9830,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2015,
						'Heat Infil' => 15557,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 1606,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => -322,
						'Cool Infil Sens' => 1911,
						'Cool Infil Lat' => -3140,
						'Cool IntGains Sens' => 2807,
						'Cool IntGains Lat' => 1059,
						'Heat Load' => 38521,
						'Cool Load Sens' => 12634,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -143,
						'Dehumid Load Lat' => -86,
						'Heat Airflow' => 0,
						'Cool Airflow' => 820,
						'HeatingLoad' => 38521,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 12634,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -143,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_loads_2story_crawlspace_garage_finished_attic_ducts_in_crawl
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1553,
						'DehumidLoad_Inf_Lat' => -1150,
						'DehumidLoad_Int_Sens' => 2232,
						'DehumidLoad_Int_Lat' => 1064,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 9830,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2015,
						'Heat Infil' => 15557,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 1606,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => -322,
						'Cool Infil Sens' => 1911,
						'Cool Infil Lat' => -3140,
						'Cool IntGains Sens' => 2807,
						'Cool IntGains Lat' => 1059,
						'Heat Load' => 38521,
						'Cool Load Sens' => 12634,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -143,
						'Dehumid Load Lat' => -86,
						'Heat Airflow' => 1215,
						'Cool Airflow' => 882,
						'HeatingLoad' => 45319,
						'HeatingDuctLoad' => 6798,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13592,
						'CoolingLoad_Ducts_Lat' => 89,
						'CoolingLoad_Ducts_Sens' => 868,
						'DehumidLoad_Sens' => -178,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 16334,
						'Cool_SensCap' => 10519,
						'Heat_Capacity' => 16334,
						'SuppHeat_Capacity' => 45319,
						'Cool_AirFlowRate' => 679,
						'Heat_AirFlowRate' => 515,
						'Fan_AirFlowRate' => 679,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA_ASHP_DuctsInCS.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

# FIXME: These two tests are sometimes failing
=begin  
  def test_loads_2story_crawlspace_garage_finished_attic_ducts_in_finished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1553,
						'DehumidLoad_Inf_Lat' => -1150,
						'DehumidLoad_Int_Sens' => 2232,
						'DehumidLoad_Int_Lat' => 1064,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 9830,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2015,
						'Heat Infil' => 15557,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 1606,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => -322,
						'Cool Infil Sens' => 1911,
						'Cool Infil Lat' => -3140,
						'Cool IntGains Sens' => 2807,
						'Cool IntGains Lat' => 1059,
						'Heat Load' => 38521,
						'Cool Load Sens' => 12634,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -143,
						'Dehumid Load Lat' => -86,
						'Heat Airflow' => 1215,
						'Cool Airflow' => 820,
						'HeatingLoad' => 38521,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 12634,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -143,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 15184,
						'Cool_SensCap' => 9778,
						'Heat_Capacity' => 15184,
						'SuppHeat_Capacity' => 38521,
						'Cool_AirFlowRate' => 631,
						'Heat_AirFlowRate' => 478,
						'Fan_AirFlowRate' => 631,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA_ASHP_DuctsInFA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_loads_2story_crawlspace_garage_finished_attic_ducts_in_living
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1553,
						'DehumidLoad_Inf_Lat' => -1150,
						'DehumidLoad_Int_Sens' => 2232,
						'DehumidLoad_Int_Lat' => 1064,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 9830,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2015,
						'Heat Infil' => 15557,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 1606,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => -322,
						'Cool Infil Sens' => 1911,
						'Cool Infil Lat' => -3140,
						'Cool IntGains Sens' => 2807,
						'Cool IntGains Lat' => 1059,
						'Heat Load' => 38521,
						'Cool Load Sens' => 12634,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -143,
						'Dehumid Load Lat' => -86,
						'Heat Airflow' => 1215,
						'Cool Airflow' => 820,
						'HeatingLoad' => 38521,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 12634,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -143,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 15184,
						'Cool_SensCap' => 9778,
						'Heat_Capacity' => 15184,
						'SuppHeat_Capacity' => 38521,
						'Cool_AirFlowRate' => 631,
						'Heat_AirFlowRate' => 478,
						'Fan_AirFlowRate' => 631,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA_ASHP_DuctsInLiv.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
=end
  
  def test_loads_2story_crawlspace_garage_finished_attic_ducts_in_garage
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1553,
						'DehumidLoad_Inf_Lat' => -1150,
						'DehumidLoad_Int_Sens' => 2232,
						'DehumidLoad_Int_Lat' => 1064,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 9830,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2015,
						'Heat Infil' => 15557,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 1606,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => -322,
						'Cool Infil Sens' => 1911,
						'Cool Infil Lat' => -3140,
						'Cool IntGains Sens' => 2807,
						'Cool IntGains Lat' => 1059,
						'Heat Load' => 38521,
						'Cool Load Sens' => 12634,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -143,
						'Dehumid Load Lat' => -86,
						'Heat Airflow' => 1215,
						'Cool Airflow' => 1489,
						'HeatingLoad' => 80320,
						'HeatingDuctLoad' => 41798,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 22930,
						'CoolingLoad_Ducts_Lat' => -432,
						'CoolingLoad_Ducts_Sens' => 10728,
						'DehumidLoad_Sens' => -193,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 27557,
						'Cool_SensCap' => 17747,
						'Heat_Capacity' => 27557,
						'SuppHeat_Capacity' => 80320,
						'Cool_AirFlowRate' => 1145,
						'Heat_AirFlowRate' => 869,
						'Fan_AirFlowRate' => 1145,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA_ASHP_DuctsInGRG.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_loads_2story_slab_garage_finished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1553,
						'DehumidLoad_Inf_Lat' => -1150,
						'DehumidLoad_Int_Sens' => 2232,
						'DehumidLoad_Int_Lat' => 1064,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 9830,
						'Heat Roofs' => 2242,
						'Heat Floors' => 3250,
						'Heat Infil' => 15557,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1911,
						'Cool Infil Lat' => -3140,
						'Cool IntGains Sens' => 2807,
						'Cool IntGains Lat' => 1059,
						'Heat Load' => 39757,
						'Cool Load Sens' => 13187,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1739,
						'Dehumid Load Lat' => -86,
						'Heat Airflow' => 0,
						'Cool Airflow' => 856,
						'HeatingLoad' => 39757,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13187,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1739,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_2story_S_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_loads_1story_slab_unfinished_attic_vented
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -689,
						'DehumidLoad_Inf_Lat' => -510,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 4030,
						'Heat Doors' => 252,
						'Heat Walls' => 4086,
						'Heat Roofs' => 0,
						'Heat Floors' => 4338,
						'Heat Infil' => 6048,
						'Dehumid Windows' => -492,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -499,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 212,
						'Cool Windows' => 2445,
						'Cool Doors' => 91,
						'Cool Walls' => 649,
						'Cool Roofs' => 0,
						'Cool Floors' => 1011,
						'Cool Infil Sens' => 817,
						'Cool Infil Lat' => -1343,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 18756,
						'Cool Load Sens' => 7562,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => 554,
						'Dehumid Load Lat' => 549,
						'Heat Airflow' => 0,
						'Cool Airflow' => 491,
						'HeatingLoad' => 18756,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 7562,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 554,
						'DehumidLoad_Ducts_Lat' => 549,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Vented.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end
  
  def test_loads_1story_slab_unfinished_attic_unvented_roof_ins
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -689,
						'DehumidLoad_Inf_Lat' => -510,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 4030,
						'Heat Doors' => 252,
						'Heat Walls' => 4086,
						'Heat Roofs' => 0,
						'Heat Floors' => 5200,
						'Heat Infil' => 6048,
						'Dehumid Windows' => -492,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -499,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 317,
						'Cool Windows' => 2445,
						'Cool Doors' => 91,
						'Cool Walls' => 649,
						'Cool Roofs' => 0,
						'Cool Floors' => 4000,
						'Cool Infil Sens' => 817,
						'Cool Infil Lat' => -1343,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 19618,
						'Cool Load Sens' => 10551,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => 659,
						'Dehumid Load Lat' => 549,
						'Heat Airflow' => 0,
						'Cool Airflow' => 685,
						'HeatingLoad' => 19618,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 10551,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 659,
						'DehumidLoad_Ducts_Lat' => 549,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_InsRoof.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_slab_unfinished_attic_unvented_no_overhangs_no_interior_shading_no_mech_vent
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -635,
						'DehumidLoad_Inf_Lat' => -470,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 4030,
						'Heat Doors' => 252,
						'Heat Walls' => 4086,
						'Heat Roofs' => 0,
						'Heat Floors' => 4338,
						'Heat Infil' => 5631,
						'Dehumid Windows' => -492,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -499,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 212,
						'Cool Windows' => 4262,
						'Cool Doors' => 91,
						'Cool Walls' => 649,
						'Cool Roofs' => 0,
						'Cool Floors' => 1609,
						'Cool Infil Sens' => 571,
						'Cool Infil Lat' => -939,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 18340,
						'Cool Load Sens' => 9731,
						'Cool Load Lat' => 114,
						'Dehumid Load Sens' => 608,
						'Dehumid Load Lat' => 589,
						'Heat Airflow' => 0,
						'Cool Airflow' => 631,
						'HeatingLoad' => 18340,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 114,
						'CoolingLoad_Sens' => 9731,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 608,
						'DehumidLoad_Ducts_Lat' => 589,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_NoOverhangs_NoIntShading_NoMechVent.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end
  
  def test_loads_1story_slab_unfinished_attic_unvented_no_overhangs_no_interior_shading_supply_mech_vent
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -575,
						'DehumidLoad_Inf_Lat' => -425,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 4030,
						'Heat Doors' => 252,
						'Heat Walls' => 4086,
						'Heat Roofs' => 0,
						'Heat Floors' => 4338,
						'Heat Infil' => 5182,
						'Dehumid Windows' => -492,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -499,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 212,
						'Cool Windows' => 4262,
						'Cool Doors' => 91,
						'Cool Walls' => 649,
						'Cool Roofs' => 0,
						'Cool Floors' => 1609,
						'Cool Infil Sens' => 122,
						'Cool Infil Lat' => -200,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 17890,
						'Cool Load Sens' => 9282,
						'Cool Load Lat' => 852,
						'Dehumid Load Sens' => 668,
						'Dehumid Load Lat' => 634,
						'Heat Airflow' => 0,
						'Cool Airflow' => 602,
						'HeatingLoad' => 17890,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 852,
						'CoolingLoad_Sens' => 9282,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 668,
						'DehumidLoad_Ducts_Lat' => 634,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_NoOverhangs_NoIntShading_SupplyMechVent.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_slab_unfinished_attic_unvented_no_overhangs_no_interior_shading_erv
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -693,
						'DehumidLoad_Inf_Lat' => -580,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 4030,
						'Heat Doors' => 252,
						'Heat Walls' => 4086,
						'Heat Roofs' => 0,
						'Heat Floors' => 4338,
						'Heat Infil' => 6108,
						'Dehumid Windows' => -492,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -499,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 212,
						'Cool Windows' => 4262,
						'Cool Doors' => 91,
						'Cool Walls' => 649,
						'Cool Roofs' => 0,
						'Cool Floors' => 1609,
						'Cool Infil Sens' => 697,
						'Cool Infil Lat' => -1468,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 18816,
						'Cool Load Sens' => 9858,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => 550,
						'Dehumid Load Lat' => 479,
						'Heat Airflow' => 0,
						'Cool Airflow' => 640,
						'HeatingLoad' => 18816,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 9858,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 550,
						'DehumidLoad_Ducts_Lat' => 479,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_NoOverhangs_NoIntShading_ERV.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end
  
  def test_loads_1story_slab_unfinished_attic_unvented_no_overhangs_no_interior_shading_hrv
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -698,
						'DehumidLoad_Inf_Lat' => -669,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 4030,
						'Heat Doors' => 252,
						'Heat Walls' => 4086,
						'Heat Roofs' => 0,
						'Heat Floors' => 4338,
						'Heat Infil' => 6153,
						'Dehumid Windows' => -492,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -499,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 212,
						'Cool Windows' => 4262,
						'Cool Doors' => 91,
						'Cool Walls' => 649,
						'Cool Roofs' => 0,
						'Cool Floors' => 1609,
						'Cool Infil Sens' => 710,
						'Cool Infil Lat' => -1899,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 18862,
						'Cool Load Sens' => 9870,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => 545,
						'Dehumid Load Lat' => 390,
						'Heat Airflow' => 0,
						'Cool Airflow' => 640,
						'HeatingLoad' => 18862,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 9870,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 545,
						'DehumidLoad_Ducts_Lat' => 390,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_NoOverhangs_NoIntShading_HRV.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end
  
  def test_loads_1story_slab_unfinished_attic_vented_atlanta_darkextfin
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => 413,
						'DehumidLoad_Inf_Lat' => 2622,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 2824,
						'Heat Doors' => 177,
						'Heat Walls' => 2864,
						'Heat Roofs' => 0,
						'Heat Floors' => 2755,
						'Heat Infil' => 4488,
						'Dehumid Windows' => 276,
						'Dehumid Doors' => 17,
						'Dehumid Walls' => 280,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => -119,
						'Cool Windows' => 2429,
						'Cool Doors' => 109,
						'Cool Walls' => 1277,
						'Cool Roofs' => 0,
						'Cool Floors' => 1138,
						'Cool Infil Sens' => 925,
						'Cool Infil Lat' => 960,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 13110,
						'Cool Load Sens' => 8427,
						'Cool Load Lat' => 2014,
						'Dehumid Load Sens' => 2923,
						'Dehumid Load Lat' => 3682,
						'Heat Airflow' => 0,
						'Cool Airflow' => 386,
						'HeatingLoad' => 13110,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 2014,
						'CoolingLoad_Sens' => 8427,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 2923,
						'DehumidLoad_Ducts_Lat' => 3682,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Vented_Atlanta_ExtFinDark.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end
  
  def test_loads_1story_slab_unfinished_attic_vented_losangeles
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -262,
						'DehumidLoad_Inf_Lat' => 799,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 1504,
						'Heat Doors' => 94,
						'Heat Walls' => 1526,
						'Heat Roofs' => 0,
						'Heat Floors' => 1601,
						'Heat Infil' => 2121,
						'Dehumid Windows' => -193,
						'Dehumid Doors' => -12,
						'Dehumid Walls' => -196,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 83,
						'Cool Windows' => 1940,
						'Cool Doors' => 81,
						'Cool Walls' => 95,
						'Cool Roofs' => 0,
						'Cool Floors' => 946,
						'Cool Infil Sens' => 300,
						'Cool Infil Lat' => -195,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 6848,
						'Cool Load Sens' => 5911,
						'Cool Load Lat' => 858,
						'Dehumid Load Sens' => 1472,
						'Dehumid Load Lat' => 1859,
						'Heat Airflow' => 0,
						'Cool Airflow' => 317,
						'HeatingLoad' => 6848,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 858,
						'CoolingLoad_Sens' => 5911,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 1472,
						'DehumidLoad_Ducts_Lat' => 1859,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Vented_LosAngeles.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end
  
  def test_loads_1story_pierbeam_unfinished_attic_vented
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -635,
						'DehumidLoad_Inf_Lat' => -470,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 4030,
						'Heat Doors' => 252,
						'Heat Walls' => 4086,
						'Heat Roofs' => 0,
						'Heat Floors' => 4027,
						'Heat Infil' => 6035,
						'Dehumid Windows' => -492,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -499,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 531,
						'Cool Windows' => 2445,
						'Cool Doors' => 91,
						'Cool Walls' => 649,
						'Cool Roofs' => 0,
						'Cool Floors' => 1592,
						'Cool Infil Sens' => 849,
						'Cool Infil Lat' => -1394,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 18432,
						'Cool Load Sens' => 8174,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => 927,
						'Dehumid Load Lat' => 589,
						'Heat Airflow' => 0,
						'Cool Airflow' => 530,
						'HeatingLoad' => 18432,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 8174,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 927,
						'DehumidLoad_Ducts_Lat' => 589,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_PB_UA_Vented.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_pierbeam_unfinished_attic_vented_ducts_in_pierbeam
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -635,
						'DehumidLoad_Inf_Lat' => -470,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 4030,
						'Heat Doors' => 252,
						'Heat Walls' => 4086,
						'Heat Roofs' => 0,
						'Heat Floors' => 4027,
						'Heat Infil' => 6035,
						'Dehumid Windows' => -492,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -499,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 531,
						'Cool Windows' => 2445,
						'Cool Doors' => 91,
						'Cool Walls' => 649,
						'Cool Roofs' => 0,
						'Cool Floors' => 1592,
						'Cool Infil Sens' => 849,
						'Cool Infil Lat' => -1394,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 18432,
						'Cool Load Sens' => 8174,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => 927,
						'Dehumid Load Lat' => 589,
						'Heat Airflow' => 581,
						'Cool Airflow' => 863,
						'HeatingLoad' => 41478,
						'HeatingDuctLoad' => 23046,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13292,
						'CoolingLoad_Ducts_Lat' => -520,
						'CoolingLoad_Ducts_Sens' => 5637,
						'DehumidLoad_Sens' => 1551,
						'DehumidLoad_Ducts_Lat' => 538,
						'Cool_Capacity' => 15974,
						'Cool_SensCap' => 10287,
						'Heat_Capacity' => 15974,
						'SuppHeat_Capacity' => 41478,
						'Cool_AirFlowRate' => 664,
						'Heat_AirFlowRate' => 503,
						'Fan_AirFlowRate' => 664,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_PB_UA_Vented_ASHP_DuctsInPB.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end  

  def test_loads_1story_pierbeam_unfinished_attic_vented_ducts_in_unfinished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -635,
						'DehumidLoad_Inf_Lat' => -470,
						'DehumidLoad_Int_Sens' => 2053,
						'DehumidLoad_Int_Lat' => 1060,
						'Heat Windows' => 4030,
						'Heat Doors' => 252,
						'Heat Walls' => 4086,
						'Heat Roofs' => 0,
						'Heat Floors' => 4027,
						'Heat Infil' => 6035,
						'Dehumid Windows' => -492,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -499,
						'Dehumid Roofs' => 0,
						'Dehumid Floors' => 531,
						'Cool Windows' => 2445,
						'Cool Doors' => 91,
						'Cool Walls' => 649,
						'Cool Roofs' => 0,
						'Cool Floors' => 2074,
						'Cool Infil Sens' => 849,
						'Cool Infil Lat' => -1394,
						'Cool IntGains Sens' => 2547,
						'Cool IntGains Lat' => 1053,
						'Heat Load' => 18432,
						'Cool Load Sens' => 8656,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => 927,
						'Dehumid Load Lat' => 589,
						'Heat Airflow' => 581,
						'Cool Airflow' => 562,
						'HeatingLoad' => 42640,
						'HeatingDuctLoad' => 24208,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26326,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 17670,
						'DehumidLoad_Sens' => 1351,
						'DehumidLoad_Ducts_Lat' => 544,
						'Cool_Capacity' => 31638,
						'Cool_SensCap' => 20375,
						'Heat_Capacity' => 31638,
						'SuppHeat_Capacity' => 42640,
						'Cool_AirFlowRate' => 1315,
						'Heat_AirFlowRate' => 997,
						'Fan_AirFlowRate' => 1315,
						'Dehumid_WaterRemoval_Auto' => 0,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_PB_UA_Vented_ASHP_DuctsInUA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end  
  
  def test_equip_ASHP_one_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 94511,
						'HeatingDuctLoad' => 52923,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 32173,
						'Cool_SensCap' => 20720,
						'Heat_Capacity' => 32173,
						'SuppHeat_Capacity' => 94511,
						'Cool_AirFlowRate' => 1337,
						'Heat_AirFlowRate' => 1014,
						'Fan_AirFlowRate' => 1337,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.631409756356,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.631409756356,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Heating Operation {m3/s}' => 0.478945768651,
						'Coil:Heating:DX:SingleSpeed_Rated Total Heating Capacity {W}' => 9430.05384169,
						'Coil:Heating:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.478945768651,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 27701.2991485,
						'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}' => 9430.05384169,
						'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.498801054019,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.63141447583,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.602431857529,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0289778988267,
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP1_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_ASHP_one_speed_autosize_min_temp
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 94511,
						'HeatingDuctLoad' => 52923,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 32173,
						'Cool_SensCap' => 20720,
						'Heat_Capacity' => 32173,
						'SuppHeat_Capacity' => 94511,
						'Cool_AirFlowRate' => 1337,
						'Heat_AirFlowRate' => 1014,
						'Fan_AirFlowRate' => 1337,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.631409756356,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.631409756356,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Heating Operation {m3/s}' => 0.478945768651,
						'Coil:Heating:DX:SingleSpeed_Rated Total Heating Capacity {W}' => 9430.05384169,
						'Coil:Heating:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.478945768651,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 27701.2991485,
						'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}' => 9430.05384169,
						'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.498801054019,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.63141447583,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.602431857529,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0289778988267,
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP1_Autosize_MinTemp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_equip_ASHP_one_speed_autosize_for_max_load_min_temp
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 94511,
						'HeatingDuctLoad' => 52923,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 86281,
						'Cool_SensCap' => 20720,
						'Heat_Capacity' => 86281,
						'SuppHeat_Capacity' => 94511,
						'Cool_AirFlowRate' => 3587,
						'Heat_AirFlowRate' => 2721,
						'Fan_AirFlowRate' => 3587,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 1.69329582895,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Cooling Operation {m3/s}' => 1.69329582895,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Heating Operation {m3/s}' => 1.28442245972,
						'Coil:Heating:DX:SingleSpeed_Rated Total Heating Capacity {W}' => 25289.2367851,
						'Coil:Heating:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 1.28442245972,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 27701.2991485,
						'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}' => 25289.2367851,
						'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 1.33766977109,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 1.69330054843,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 1.61558376524,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0777120637132,
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP1_AutosizeForMaxLoad_MinTemp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_ASHP_one_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 50000,
						'HeatingDuctLoad' => 52923,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 60000,
						'Cool_SensCap' => 20720,
						'Heat_Capacity' => 50000,
						'SuppHeat_Capacity' => 50000,
						'Cool_AirFlowRate' => 1163,
						'Heat_AirFlowRate' => 1577,
						'Fan_AirFlowRate' => 1577,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.744317090593,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.549051962049,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Heating Operation {m3/s}' => 0.744317090593,
						'Coil:Heating:DX:SingleSpeed_Rated Total Heating Capacity {W}' => 14655.0,
						'Coil:Heating:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.744317090593,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 14655.0,
						'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}' => 17586.0,
						'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.93020840424,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.744321810068,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.679747518362,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0645695722313,
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_ASHP_two_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 94511,
						'HeatingDuctLoad' => 52923,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 33858,
						'Cool_SensCap' => 20505,
						'Heat_Capacity' => 33858,
						'SuppHeat_Capacity' => 94511,
						'Cool_AirFlowRate' => 1407,
						'Heat_AirFlowRate' => 1067,
						'Fan_AirFlowRate' => 1407,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.66448027127,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.433466555629,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.504030878639,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.571453033292,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.66448027127,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Total Heating Capacity {W}' => 7145.25070868,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.375198319104,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Total Heating Capacity {W}' => 9923.95931761,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.46899789888,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 27701.2991485,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Total Cooling Capacity {W}' => 7145.25070868,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.394062101715,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Total Cooling Capacity {W}' => 9923.95931761,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.45821174618,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.664484990744,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.633984635307,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0304956359628,
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP2_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_ASHP_two_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 50000,
						'HeatingDuctLoad' => 52923,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 60000,
						'Cool_SensCap' => 20505,
						'Heat_Capacity' => 50000,
						'SuppHeat_Capacity' => 50000,
						'Cool_AirFlowRate' => 1173,
						'Heat_AirFlowRate' => 1577,
						'Fan_AirFlowRate' => 1577,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.744317090593,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.64011269791,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.744317090593,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.476210861077,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.553733559391,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Total Heating Capacity {W}' => 10551.6,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.55406629456,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Total Heating Capacity {W}' => 14655.0,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.6925828682,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 14655.0,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Total Cooling Capacity {W}' => 12661.92,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.698307590647,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Total Cooling Capacity {W}' => 17586.0,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.81198557052,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.744321810068,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.679747518362,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0645695722313,
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP2_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end   
  
  def test_equip_ASHP_variable_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 94511,
						'HeatingDuctLoad' => 52923,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 35655,
						'Cool_SensCap' => 19306,
						'Heat_Capacity' => 35655,
						'SuppHeat_Capacity' => 94511,
						'Cool_AirFlowRate' => 1482,
						'Heat_AirFlowRate' => 1124,
						'Fan_AirFlowRate' => 1482,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.881686763127,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.371549659952,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.477706705652,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 3 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.530785228503,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 4 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.668789387913,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.489825979515,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.629776259376,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 3 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.699751399307,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed N Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.881686763127,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Total Heating Capacity {W}' => 5120.85807888,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.308095352578,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Total Heating Capacity {W}' => 7001.98961806,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.383037465367,
						'Coil:Heating:DX:MultiSpeed_Speed 3 Rated Total Heating Capacity {W}' => 10450.7307732,
						'Coil:Heating:DX:MultiSpeed_Speed 3 Rated Air Flow Rate {m3/s}' => 0.416345071051,
						'Coil:Heating:DX:MultiSpeed_Speed 4 Rated Total Heating Capacity {W}' => 12540.8769279,
						'Coil:Heating:DX:MultiSpeed_Speed 4 Rated Air Flow Rate {m3/s}' => 0.507940986682,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 27701.2991485,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Total Cooling Capacity {W}' => 5120.85807888,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.309994076815,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Total Cooling Capacity {W}' => 7001.98961806,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.398563813048,
						'Coil:Cooling:DX:MultiSpeed_Speed 3 Rated Total Cooling Capacity {W}' => 10450.7307732,
						'Coil:Cooling:DX:MultiSpeed_Speed 3 Rated Air Flow Rate {m3/s}' => 0.442848681165,
						'Coil:Cooling:DX:MultiSpeed_Speed 4 Rated Total Cooling Capacity {W}' => 12540.8769279,
						'Coil:Cooling:DX:MultiSpeed_Speed 4 Rated Air Flow Rate {m3/s}' => 0.557989338268,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.881692709665,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.667637031341,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0321143679661,
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHPV_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_ASHP_variable_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 50000,
						'HeatingDuctLoad' => 52923,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 60000,
						'Cool_SensCap' => 19306,
						'Heat_Capacity' => 50000,
						'SuppHeat_Capacity' => 50000,
						'Cool_AirFlowRate' => 1140,
						'Heat_AirFlowRate' => 1577,
						'Fan_AirFlowRate' => 1577,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.937839534148,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.521021963415,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.669885381534,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 3 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.744317090593,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 4 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.937839534148,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.376789215012,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.484443276443,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 3 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.538270307159,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed N Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.678220587021,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Total Heating Capacity {W}' => 7180.95,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.432040351053,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Total Heating Capacity {W}' => 9818.85,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.537131247255,
						'Coil:Heating:DX:MultiSpeed_Speed 3 Rated Total Heating Capacity {W}' => 14655.0,
						'Coil:Heating:DX:MultiSpeed_Speed 3 Rated Air Flow Rate {m3/s}' => 0.583838312233,
						'Coil:Heating:DX:MultiSpeed_Speed 4 Rated Total Heating Capacity {W}' => 17586.0,
						'Coil:Heating:DX:MultiSpeed_Speed 4 Rated Air Flow Rate {m3/s}' => 0.712282740925,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 14655.0,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Total Cooling Capacity {W}' => 8617.14,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.521643505432,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Total Cooling Capacity {W}' => 11782.62,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.670684506984,
						'Coil:Cooling:DX:MultiSpeed_Speed 3 Rated Total Cooling Capacity {W}' => 17586.0,
						'Coil:Cooling:DX:MultiSpeed_Speed 3 Rated Air Flow Rate {m3/s}' => 0.74520500776,
						'Coil:Cooling:DX:MultiSpeed_Speed 4 Rated Total Cooling Capacity {W}' => 21103.2,
						'Coil:Cooling:DX:MultiSpeed_Speed 4 Rated Air Flow Rate {m3/s}' => 0.938958309778,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.937845480685,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.679747518362,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0645695722313,
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHPV_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_electric_baseboard_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 0,
						'Cool Airflow' => 866,
						'HeatingLoad' => 41587,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 41587,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
						'ZoneHVAC:Baseboard:Convective:Electric_Living_Heating Design Capacity {W}' => 12189.3551749,
						'ZoneHVAC:Baseboard:Convective:Electric_Basement_Heating Design Capacity {W}' => 12189.3551749,
                      }
    _test_measure("SFD_HVACSizing_Equip_BB_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_equip_electric_baseboard_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 0,
						'Cool Airflow' => 866,
						'HeatingLoad' => 100000,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 100000,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
						'ZoneHVAC:Baseboard:Convective:Electric_Living_Heating Design Capacity {W}' => 29310.0,
						'ZoneHVAC:Baseboard:Convective:Electric_Basement_Heating Design Capacity {W}' => 29310.0,
                      }
    _test_measure("SFD_HVACSizing_Equip_BB_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_electric_boiler_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 0,
						'Cool Airflow' => 866,
						'HeatingLoad' => 41587,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 41587,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
						'Pump:VariableSpeed_Design Flow Rate {m3/s}' => 0.000262377620982,
						'Boiler:HotWater_Nomimal Capacity {W}' => 12189.3551749,
						'ZoneHVAC:Baseboard:Convective:Water_Living_U-Factor Times Area Value {W/K}' => 877.633572593,
						'ZoneHVAC:Baseboard:Convective:Water_Living_Maximum Water Flow rate {m3/s}' => 0.000525093264264,
						'ZoneHVAC:Baseboard:Convective:Water_Basement_U-Factor Times Area Value {W/K}' => 877.633572593,
						'ZoneHVAC:Baseboard:Convective:Water_Basement_Maximum Water Flow rate {m3/s}' => 0.000525093264264,    
                      }
    _test_measure("SFD_HVACSizing_Equip_ElecBoiler_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_equip_electric_boiler_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 0,
						'Cool Airflow' => 866,
						'HeatingLoad' => 100000,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 100000,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 0,
						'Pump:VariableSpeed_Design Flow Rate {m3/s}' => 0.00063090196,
						'Boiler:HotWater_Nomimal Capacity {W}' => 29310.0,
						'ZoneHVAC:Baseboard:Convective:Water_Living_U-Factor Times Area Value {W/K}' => 2110.32,
						'ZoneHVAC:Baseboard:Convective:Water_Living_Maximum Water Flow rate {m3/s}' => 0.00126261671391,
						'ZoneHVAC:Baseboard:Convective:Water_Basement_U-Factor Times Area Value {W/K}' => 2110.32,
						'ZoneHVAC:Baseboard:Convective:Water_Basement_Maximum Water Flow rate {m3/s}' => 0.00126261671391,
                      }
    _test_measure("SFD_HVACSizing_Equip_ElecBoiler_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_gas_furnace_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 866,
						'HeatingLoad' => 92501,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 92501,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 2042,
						'Fan_AirFlowRate' => 2042,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatOnly_Supply Air Flow Rate {m3/s}' => 0.963903000253,
						'Coil:Heating:Fuel_Nominal Capacity {W}' => 27112.097878,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.963907719728,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.918704299692,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_gas_furnace_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 866,
						'HeatingLoad' => 100000,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 100000,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 2207,
						'Fan_AirFlowRate' => 2207,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatOnly_Supply Air Flow Rate {m3/s}' => 1.04204392683,
						'Coil:Heating:Fuel_Nominal Capacity {W}' => 29310.0,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 1.0420486463,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.996845226269,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end    

  def test_equip_gas_furnace_and_ac_one_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 92501,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 27883,
						'Cool_SensCap' => 20645,
						'Heat_Capacity' => 92501,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 1159,
						'Heat_AirFlowRate' => 2042,
						'Fan_AirFlowRate' => 2042,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatCool_Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.547225600243,
						'AirLoopHVAC:UnitaryHeatCool_Supply Air Flow Rate During Heating Operation {m3/s}' => 0.963903000253,
						'Coil:Heating:Fuel_Nominal Capacity {W}' => 27112.097878,
						'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}' => 8172.77025244,
						'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.423414437383,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.963907719728,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.918704299692,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_AC1_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_gas_furnace_and_ac_one_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 100000,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 60000,
						'Cool_SensCap' => 20645,
						'Heat_Capacity' => 100000,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 1159,
						'Heat_AirFlowRate' => 2207,
						'Fan_AirFlowRate' => 2207,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatCool_Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.547225600243,
						'AirLoopHVAC:UnitaryHeatCool_Supply Air Flow Rate During Heating Operation {m3/s}' => 1.04204392683,
						'Coil:Heating:Fuel_Nominal Capacity {W}' => 29310.0,
						'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}' => 17586.0,
						'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.91109453292,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 1.0420486463,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.996845226269,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_AC1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_equip_electric_furnace_and_ac_two_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 92501,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 27997,
						'Cool_SensCap' => 20543,
						'Heat_Capacity' => 92501,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 1164,
						'Heat_AirFlowRate' => 2042,
						'Fan_AirFlowRate' => 2042,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.472529488808,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.549452893963,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 27112.097878,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Total Heating Capacity {W}' => 27112.097878,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 1.3556048939,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Total Heating Capacity {W}' => 27112.097878,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 1.3556048939,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Total Cooling Capacity {W}' => 5908.34498738,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.336357664177,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Total Cooling Capacity {W}' => 8206.0347047,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.391113562997,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.963907719728,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.918704299692,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_EF_AC2_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_electric_furnace_and_ac_two_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 100000,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 60000,
						'Cool_SensCap' => 20543,
						'Heat_Capacity' => 100000,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 1164,
						'Heat_AirFlowRate' => 2207,
						'Fan_AirFlowRate' => 2207,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Heating Operation {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Heating Operation {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.472529488808,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.549452893963,
						'Coil:Heating:Electric_Nominal Capacity {W}' => 29310.0,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Total Heating Capacity {W}' => 29310.0,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 1.4655,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Total Heating Capacity {W}' => 29310.0,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 1.4655,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Total Cooling Capacity {W}' => 12661.92,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.720833641958,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Total Cooling Capacity {W}' => 17586.0,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.83817865344,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 1.0420486463,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.996845226269,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_EF_AC2_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_gas_furnace_and_ac_variable_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 92501,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 28360,
						'Cool_SensCap' => 19962,
						'Heat_Capacity' => 92501,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 1179,
						'Heat_AirFlowRate' => 2042,
						'Fan_AirFlowRate' => 2042,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 1.1470445703,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 3 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 4 Supply Air Flow Rate During Heating Operation {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.283851561451,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.467520218861,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 3 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.55657168912,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed N Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.662320310053,
						'Coil:Heating:Fuel_Nominal Capacity {W}' => 27112.097878,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Total Heating Capacity {W}' => 27112.097878,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 1.3556048939,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Total Heating Capacity {W}' => 27112.097878,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 1.3556048939,
						'Coil:Heating:DX:MultiSpeed_Speed 3 Rated Total Heating Capacity {W}' => 27112.097878,
						'Coil:Heating:DX:MultiSpeed_Speed 3 Rated Air Flow Rate {m3/s}' => 1.3556048939,
						'Coil:Heating:DX:MultiSpeed_Speed 4 Rated Total Heating Capacity {W}' => 27112.097878,
						'Coil:Heating:DX:MultiSpeed_Speed 4 Rated Air Flow Rate {m3/s}' => 1.3556048939,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Total Cooling Capacity {W}' => 2992.44720127,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.179639926065,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Total Cooling Capacity {W}' => 5319.90613558,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.295877525283,
						'Coil:Cooling:DX:MultiSpeed_Speed 3 Rated Total Cooling Capacity {W}' => 8312.35333685,
						'Coil:Cooling:DX:MultiSpeed_Speed 3 Rated Air Flow Rate {m3/s}' => 0.352235149146,
						'Coil:Cooling:DX:MultiSpeed_Speed 4 Rated Total Cooling Capacity {W}' => 9642.32987074,
						'Coil:Cooling:DX:MultiSpeed_Speed 4 Rated Air Flow Rate {m3/s}' => 0.419159827484,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 1.14705018648,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.918704299692,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_ACV_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_gas_furnace_and_ac_variable_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 1738,
						'HeatingLoad' => 100000,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 26771,
						'CoolingLoad_Ducts_Lat' => -609,
						'CoolingLoad_Ducts_Sens' => 14036,
						'DehumidLoad_Sens' => -2314,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 60000,
						'Cool_SensCap' => 19962,
						'Heat_Capacity' => 100000,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 1179,
						'Heat_AirFlowRate' => 2207,
						'Fan_AirFlowRate' => 2207,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 1.24003227293,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Heating Operation {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Heating Operation {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 3 Supply Air Flow Rate During Heating Operation {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 4 Supply Air Flow Rate During Heating Operation {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 1 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.283851561451,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 2 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.467520218861,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed 3 Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.55657168912,
						'AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed N Supply Air Flow Rate During Cooling Operation {m3/s}' => 0.662320310053,
						'Coil:Heating:Fuel_Nominal Capacity {W}' => 29310.0,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Total Heating Capacity {W}' => 29310.0,
						'Coil:Heating:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 1.4655,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Total Heating Capacity {W}' => 29310.0,
						'Coil:Heating:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 1.4655,
						'Coil:Heating:DX:MultiSpeed_Speed 3 Rated Total Heating Capacity {W}' => 29310.0,
						'Coil:Heating:DX:MultiSpeed_Speed 3 Rated Air Flow Rate {m3/s}' => 1.4655,
						'Coil:Heating:DX:MultiSpeed_Speed 4 Rated Total Heating Capacity {W}' => 29310.0,
						'Coil:Heating:DX:MultiSpeed_Speed 4 Rated Air Flow Rate {m3/s}' => 1.4655,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Total Cooling Capacity {W}' => 6330.96,
						'Coil:Cooling:DX:MultiSpeed_Speed 1 Rated Air Flow Rate {m3/s}' => 0.380054553958,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Total Cooling Capacity {W}' => 11255.04,
						'Coil:Cooling:DX:MultiSpeed_Speed 2 Rated Air Flow Rate {m3/s}' => 0.625972206518,
						'Coil:Cooling:DX:MultiSpeed_Speed 3 Rated Total Cooling Capacity {W}' => 17586.0,
						'Coil:Cooling:DX:MultiSpeed_Speed 3 Rated Air Flow Rate {m3/s}' => 0.74520500776,
						'Coil:Cooling:DX:MultiSpeed_Speed 4 Rated Total Cooling Capacity {W}' => 20399.76,
						'Coil:Cooling:DX:MultiSpeed_Speed 4 Rated Air Flow Rate {m3/s}' => 0.886793959234,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 1.2400378891,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.996845226269,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_ACV_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end 
  
  def test_equip_gas_furnace_and_room_air_conditioner_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 866,
						'HeatingLoad' => 92501,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 14172,
						'Cool_SensCap' => 9212,
						'Heat_Capacity' => 92501,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 413,
						'Heat_AirFlowRate' => 2042,
						'Fan_AirFlowRate' => 2042,
						'Dehumid_WaterRemoval_Auto' => 0,
						'ZoneHVAC:WindowAirConditioner_Maximum Supply Air Flow Rate {m3/s}' => 0.195088648373,
						'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}' => 4154.00854236,
						'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.173907595121,
						'Fan:OnOff_Maximum Flow Rate {m3/s}' => 0.195088648373,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 0.963903000253,
						'AirLoopHVAC:UnitaryHeatOnly_Supply Air Flow Rate {m3/s}' => 0.963903000253,
						'Coil:Heating:Fuel_Nominal Capacity {W}' => 27112.097878,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.963907719728,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.918704299692,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_RAC_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_gas_furnace_and_room_air_conditioner_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 918,
						'Cool Airflow' => 866,
						'HeatingLoad' => 100000,
						'HeatingDuctLoad' => 50913,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 36000,
						'Cool_SensCap' => 9212,
						'Heat_Capacity' => 100000,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 413,
						'Heat_AirFlowRate' => 2207,
						'Fan_AirFlowRate' => 2207,
						'Dehumid_WaterRemoval_Auto' => 0,
						'ZoneHVAC:WindowAirConditioner_Maximum Supply Air Flow Rate {m3/s}' => 0.195088648373,
						'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}' => 10551.6,
						'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}' => 0.44174280384,
						'Fan:OnOff_Maximum Flow Rate {m3/s}' => 0.195088648373,
						'AirLoopHVAC_Design Supply Air Flow rate {m3/s}' => 1.04204392683,
						'AirLoopHVAC:UnitaryHeatOnly_Supply Air Flow Rate {m3/s}' => 1.04204392683,
						'Coil:Heating:Fuel_Nominal Capacity {W}' => 29310.0,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 1.0420486463,
						'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}' => 0.996845226269,
						'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}' => 0.0451987005619,
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_RAC_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_mshp_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 866,
						'HeatingLoad' => 41587,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 17226,
						'Cool_SensCap' => 9284,
						'Heat_Capacity' => 19526,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 610,
						'Heat_AirFlowRate' => 650,
						'Fan_AirFlowRate' => 650,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 5426.92256703,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 6151.50626286,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 631.924185075,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 716.29648924,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 6151.50626286,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 0.2751419342,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 716.29648924,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.0320382022042,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 5426.92256703,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 0.257903881959,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 631.924185075,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.0300309610873,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.275146161444,
						'Fan:OnOff_Basement_Maximum Flow Rate {m3/s}' => 0.0320386944349,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Cooling Supply Air Flow Rate {m3/s}' => 0.257903881959,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Heating Supply Air Flow Rate {m3/s}' => 0.2751419342,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Cooling Supply Air Flow Rate {m3/s}' => 0.0300309610873,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Heating Supply Air Flow Rate {m3/s}' => 0.0320382022042,
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_mshp_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 866,
						'HeatingLoad' => 41587,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 60000,
						'Cool_SensCap' => 9284,
						'Heat_Capacity' => 62300,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 469,
						'Heat_AirFlowRate' => 2076,
						'Fan_AirFlowRate' => 2076,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 18902.1833696,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 19626.7670654,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 2201.01663041,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 2285.38893457,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 19626.7670654,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 0.877857620835,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 2285.38893457,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.102219896231,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 18902.1833696,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 0.898289299009,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 2201.01663041,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.104599010991,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.877861848079,
						'Fan:OnOff_Basement_Maximum Flow Rate {m3/s}' => 0.102220388462,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Cooling Supply Air Flow Rate {m3/s}' => 0.198387601507,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Heating Supply Air Flow Rate {m3/s}' => 0.877857620835,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Cooling Supply Air Flow Rate {m3/s}' => 0.0231007392979,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Heating Supply Air Flow Rate {m3/s}' => 0.102219896231,
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  
  
  def test_equip_mshp_autosize_for_max_load
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 866,
						'HeatingLoad' => 41587,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 80177,
						'Cool_SensCap' => 9284,
						'Heat_Capacity' => 82477,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 2839,
						'Heat_AirFlowRate' => 2749,
						'Fan_AirFlowRate' => 2839,
						'Dehumid_WaterRemoval_Auto' => 0,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 25258.8349565,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 25983.4186523,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 2941.20074475,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 3025.57304891,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 25983.4186523,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 1.16217520712,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 3025.57304891,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.135326533888,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 25258.8349565,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 1.20037673443,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 2941.20074475,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.139774813501,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 1.20038096168,
						'Fan:OnOff_Basement_Maximum Flow Rate {m3/s}' => 0.139775305731,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Cooling Supply Air Flow Rate {m3/s}' => 1.20037673443,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Heating Supply Air Flow Rate {m3/s}' => 1.16217520712,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Cooling Supply Air Flow Rate {m3/s}' => 0.139774813501,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Heating Supply Air Flow Rate {m3/s}' => 0.135326533888,
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_AutosizeForMaxLoad.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_equip_mshp_and_electric_baseboard_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 866,
						'HeatingLoad' => 41587,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 17226,
						'Cool_SensCap' => 9284,
						'Heat_Capacity' => 19526,
						'SuppHeat_Capacity' => 41587,
						'Cool_AirFlowRate' => 610,
						'Heat_AirFlowRate' => 650,
						'Fan_AirFlowRate' => 650,
						'Dehumid_WaterRemoval_Auto' => 0,
						'ZoneHVAC:Baseboard:Convective:Electric_Living_Heating Design Capacity {W}' => 12189.3551749,
						'ZoneHVAC:Baseboard:Convective:Electric_Basement_Heating Design Capacity {W}' => 12189.3551749,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 5426.92256703,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 6151.50626286,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 631.924185075,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 716.29648924,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 6151.50626286,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 0.2751419342,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 716.29648924,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.0320382022042,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 5426.92256703,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 0.257903881959,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 631.924185075,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.0300309610873,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.275146161444,
						'Fan:OnOff_Basement_Maximum Flow Rate {m3/s}' => 0.0320386944349,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Cooling Supply Air Flow Rate {m3/s}' => 0.257903881959,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Heating Supply Air Flow Rate {m3/s}' => 0.2751419342,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Cooling Supply Air Flow Rate {m3/s}' => 0.0300309610873,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Heating Supply Air Flow Rate {m3/s}' => 0.0320382022042,
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_BB_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_equip_mshp_and_electric_baseboard_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => -1567,
						'DehumidLoad_Inf_Lat' => -1161,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 8623,
						'Heat Doors' => 252,
						'Heat Walls' => 12768,
						'Heat Roofs' => 2242,
						'Heat Floors' => 2049,
						'Heat Infil' => 15650,
						'Dehumid Windows' => -1053,
						'Dehumid Doors' => -30,
						'Dehumid Walls' => -1069,
						'Dehumid Roofs' => -273,
						'Dehumid Floors' => 9,
						'Cool Windows' => 5778,
						'Cool Doors' => 91,
						'Cool Walls' => 1777,
						'Cool Roofs' => 591,
						'Cool Floors' => 230,
						'Cool Infil Sens' => 1963,
						'Cool Infil Lat' => -3226,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 41587,
						'Cool Load Sens' => 13344,
						'Cool Load Lat' => 0,
						'Dehumid Load Sens' => -1682,
						'Dehumid Load Lat' => -95,
						'Heat Airflow' => 1311,
						'Cool Airflow' => 866,
						'HeatingLoad' => 100000,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 0,
						'CoolingLoad_Sens' => 13344,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => -1682,
						'DehumidLoad_Ducts_Lat' => 0,
						'Cool_Capacity' => 60000,
						'Cool_SensCap' => 9284,
						'Heat_Capacity' => 62300,
						'SuppHeat_Capacity' => 100000,
						'Cool_AirFlowRate' => 469,
						'Heat_AirFlowRate' => 2076,
						'Fan_AirFlowRate' => 2076,
						'Dehumid_WaterRemoval_Auto' => 0,
						'ZoneHVAC:Baseboard:Convective:Electric_Living_Heating Design Capacity {W}' => 29310.0,
						'ZoneHVAC:Baseboard:Convective:Electric_Basement_Heating Design Capacity {W}' => 29310.0,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 20187.8477839,
						'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 20961.7152823,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 915.352216101,
						'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 950.440717718,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}' => 20961.7152823,
						'Coil:Heating:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 0.937566612218,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}' => 950.440717718,
						'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.0425109048484,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}' => 20187.8477839,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}' => 0.959387986018,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}' => 915.352216101,
						'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}' => 0.0435003239821,
						'Fan:OnOff_Living_Maximum Flow Rate {m3/s}' => 0.937571126985,
						'Fan:OnOff_Basement_Maximum Flow Rate {m3/s}' => 0.0425111095558,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Cooling Supply Air Flow Rate {m3/s}' => 0.211881274407,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Heating Supply Air Flow Rate {m3/s}' => 0.937566612218,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Cooling Supply Air Flow Rate {m3/s}' => 0.00960706639732,
						'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Heating Supply Air Flow Rate {m3/s}' => 0.0425109048484,
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_BB_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end  

  def test_equip_dehumidifier_autosize_atlanta
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => 925,
						'DehumidLoad_Inf_Lat' => 5865,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 6044,
						'Heat Doors' => 177,
						'Heat Walls' => 8875,
						'Heat Roofs' => 1568,
						'Heat Floors' => 1386,
						'Heat Infil' => 11343,
						'Dehumid Windows' => 592,
						'Dehumid Doors' => 17,
						'Dehumid Walls' => 391,
						'Dehumid Roofs' => 153,
						'Dehumid Floors' => -146,
						'Cool Windows' => 5791,
						'Cool Doors' => 109,
						'Cool Walls' => 2517,
						'Cool Roofs' => 754,
						'Cool Floors' => 290,
						'Cool Infil Sens' => 2218,
						'Cool Infil Lat' => 2302,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 29396,
						'Cool Load Sens' => 14593,
						'Cool Load Lat' => 3364,
						'Dehumid Load Sens' => 4236,
						'Dehumid Load Lat' => 6931,
						'Heat Airflow' => 0,
						'Cool Airflow' => 684,
						'HeatingLoad' => 29396,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 3364,
						'CoolingLoad_Sens' => 14593,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 4236,
						'DehumidLoad_Ducts_Lat' => 6931,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 80,
						'ZoneHVAC:Dehumidifier:DX_Rated Water Removal {L/day}' => 80.2567604017,
						'ZoneHVAC:Dehumidifier:DX_Rated Energy Factor {L/kWh}' => 2.5,
						'ZoneHVAC:Dehumidifier:DX_Rated Air Flow Rate {m3/s}' => 0.220132825073,
                      }
    _test_measure("SFD_HVACSizing_Equip_Dehumidifier_Auto_Atlanta.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end
  
  def test_equip_dehumidifier_fixedsize_atlanta
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
						'DehumidLoad_Inf_Sens' => 925,
						'DehumidLoad_Inf_Lat' => 5865,
						'DehumidLoad_Int_Sens' => 2303,
						'DehumidLoad_Int_Lat' => 1065,
						'Heat Windows' => 6044,
						'Heat Doors' => 177,
						'Heat Walls' => 8875,
						'Heat Roofs' => 1568,
						'Heat Floors' => 1386,
						'Heat Infil' => 11343,
						'Dehumid Windows' => 592,
						'Dehumid Doors' => 17,
						'Dehumid Walls' => 391,
						'Dehumid Roofs' => 153,
						'Dehumid Floors' => -146,
						'Cool Windows' => 5791,
						'Cool Doors' => 109,
						'Cool Walls' => 2517,
						'Cool Roofs' => 754,
						'Cool Floors' => 290,
						'Cool Infil Sens' => 2218,
						'Cool Infil Lat' => 2302,
						'Cool IntGains Sens' => 2912,
						'Cool IntGains Lat' => 1062,
						'Heat Load' => 29396,
						'Cool Load Sens' => 14593,
						'Cool Load Lat' => 3364,
						'Dehumid Load Sens' => 4236,
						'Dehumid Load Lat' => 6931,
						'Heat Airflow' => 0,
						'Cool Airflow' => 684,
						'HeatingLoad' => 29396,
						'HeatingDuctLoad' => 0,
						'CoolingLoad_Lat' => 3364,
						'CoolingLoad_Sens' => 14593,
						'CoolingLoad_Ducts_Lat' => 0,
						'CoolingLoad_Ducts_Sens' => 0,
						'DehumidLoad_Sens' => 4236,
						'DehumidLoad_Ducts_Lat' => 6931,
						'Cool_Capacity' => 0,
						'Cool_SensCap' => 0,
						'Heat_Capacity' => 0,
						'SuppHeat_Capacity' => 0,
						'Cool_AirFlowRate' => 0,
						'Heat_AirFlowRate' => 0,
						'Fan_AirFlowRate' => 0,
						'Dehumid_WaterRemoval_Auto' => 80,
						'ZoneHVAC:Dehumidifier:DX_Rated Water Removal {L/day}' => 11.82941175,
						'ZoneHVAC:Dehumidifier:DX_Rated Energy Factor {L/kWh}' => 1.2,
						'ZoneHVAC:Dehumidifier:DX_Rated Air Flow Rate {m3/s}' => 0.04153137472,
                      }
    _test_measure("SFD_HVACSizing_Equip_Dehumidifier_Fixed_Atlanta.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ProcessHVACSizing.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, apply_volume_adj=false)
  
    print_debug_info = false # set to true for more detailed output
    
    # create an instance of the measure
    measure = ProcessHVACSizing.new

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
    
    if print_debug_info
        show_output(result)
    end

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = []
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
    
    # TODO: Tighten these tolerances eventually?
    airflow_tolerance = 75 # cfm
    load_component_tolerance = 250 # Btu/hr
    load_total_tolerance = 2000 # Btu/hr
    water_removal_tolerance = 3 # L/day
    energy_factor_tolerance = 0.1 # L/kWh
    ua_tolerance = 20 # W/K
    
    # Compare intermediate values to result.info values
    map = beopt_to_os_mapping()
    expected_values.each do |beopt_key, beopt_val|
        next if map[beopt_key].nil?
        os_header = map[beopt_key][0]
        os_key = map[beopt_key][1]
        os_val = 0.0
        os_val_found = false
        result.info.map{ |x| x.logMessage }.each do |info|
            next if not info.split("\n")[0].start_with?(os_header)
            info.split("\n").each do |info_line|
                infos = info_line.split('=')
                next if infos[0].strip != os_key
                os_val += infos[1].strip.to_f
                os_val_found = true
            end
        end
        if not os_val_found
            puts "WARNING: Could not find corresponding OS value for #{beopt_key}."
            next
        end
        
        if apply_volume_adj
            if ['Heat Infil','Cool Infil Sens','Cool Infil Lat'].include?(beopt_key)
                os_above_grade_finished_volume = Geometry.get_above_grade_finished_volume_from_spaces(model.getSpaces)
                os_val = os_val * volume_adj_factor(os_above_grade_finished_volume)
            end
        end
        
        if print_debug_info
            puts "#{os_header}: #{os_key}: #{beopt_val.round(0)} (BEopt) vs. #{os_val.round(0)} (OS)"
        end
        
        if os_key.downcase.include?("water")
            assert_in_delta(beopt_val, os_val, water_removal_tolerance)
        elsif os_key.downcase.include?("airflow")
            assert_in_delta(beopt_val, os_val, airflow_tolerance)
        elsif os_header.downcase.include?("results")
            assert_in_delta(beopt_val, os_val, load_total_tolerance)
        else
            assert_in_delta(beopt_val, os_val, load_component_tolerance)
        end
    end
    
    # Check model object values
    flowrate_units = "{m3/s}"
    capacity_units = "{W}"
    water_removal_units = "{L/day}"
    energy_factor_units = "{L/kWh}"
    ua_units = "{W/K}"
    expected_values.each do |beopt_key, beopt_val|
        next if !map[beopt_key].nil?
        os_val = nil
        
        is_flowrate = false
        is_capacity = false
        is_water_removal = false
        is_energy_factor = false
        is_ua = false
        if beopt_key.include?(flowrate_units)
            is_flowrate = true
        elsif beopt_key.include?(capacity_units)
            is_capacity = true
        elsif beopt_key.include?(water_removal_units)
            is_water_removal = true
        elsif beopt_key.include?(energy_factor_units)
            is_energy_factor = true
        elsif beopt_key.include?(ua_units)
            is_ua = true
        else
            puts "WARNING: Unhandled key type: #{beopt_key}."
            next
        end
        
        if beopt_key == 'AirLoopHVAC_Design Supply Air Flow rate {m3/s}'
            ensure_num_objects(model.getAirLoopHVACs, beopt_key)
            os_val = model.getAirLoopHVACs[0].designSupplyAirFlowRate.get
            
        elsif (beopt_key == 'AirLoopHVAC:UnitaryHeatCool_Supply Air Flow Rate During Cooling Operation {m3/s}' or
               beopt_key == 'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Cooling Operation {m3/s}')
            ensure_num_objects(model.getAirLoopHVACUnitarySystems, beopt_key)
            os_val = model.getAirLoopHVACUnitarySystems[0].supplyAirFlowRateDuringCoolingOperation.get
            
        elsif beopt_key.start_with?('AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed') and beopt_key.end_with?('Supply Air Flow Rate During Cooling Operation {m3/s}')
            # FIXME: ASKJON
            next
            
        elsif (beopt_key == 'AirLoopHVAC:UnitaryHeatCool_Supply Air Flow Rate During Heating Operation {m3/s}' or 
               beopt_key == 'AirLoopHVAC:UnitaryHeatPump:AirToAir_Supply Air Flow Rate During Heating Operation {m3/s}' or 
               beopt_key == 'AirLoopHVAC:UnitaryHeatOnly_Supply Air Flow Rate {m3/s}')
            ensure_num_objects(model.getAirLoopHVACUnitarySystems, beopt_key)
            os_val = model.getAirLoopHVACUnitarySystems[0].supplyAirFlowRateDuringHeatingOperation.get
            
        elsif beopt_key.start_with?('AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed_Speed') and beopt_key.end_with?('Supply Air Flow Rate During Heating Operation {m3/s}')
            # FIXME: ASKJON
            next
            
        elsif beopt_key == 'Coil:Heating:Fuel_Nominal Capacity {W}'
            ensure_num_objects(model.getCoilHeatingGass, beopt_key)
            os_val = model.getCoilHeatingGass[0].nominalCapacity.get
            
        elsif beopt_key == 'Coil:Heating:Electric_Nominal Capacity {W}'
            ensure_num_objects(model.getCoilHeatingElectrics, beopt_key)
            os_val = model.getCoilHeatingElectrics[0].nominalCapacity.get
            
        elsif beopt_key == 'Coil:Heating:DX:SingleSpeed_Rated Total Heating Capacity {W}'
            ensure_num_objects(model.getCoilHeatingDXSingleSpeeds, beopt_key)
            os_val = model.getCoilHeatingDXSingleSpeeds[0].ratedTotalHeatingCapacity.get
            
        elsif beopt_key.start_with?('Coil:Heating:DX:MultiSpeed_Speed') and beopt_key.end_with?('Rated Total Heating Capacity {W}')
            if model.getCoilHeatingDXMultiSpeeds.size > 0
                ensure_num_objects(model.getCoilHeatingDXMultiSpeeds, beopt_key)
                speed = beopt_key.split(" ")[1].to_i
                os_val = model.getCoilHeatingDXMultiSpeeds[0].stages[speed-1].grossRatedHeatingCapacity.get
            elsif model.getCoilHeatingElectrics.size > 0
                # Electric furnace with multi-speed AC modeled as HP in BEopt
                ensure_num_objects(model.getCoilHeatingElectrics, beopt_key)
                os_val = model.getCoilHeatingElectrics[0].nominalCapacity.get
            elsif model.getCoilHeatingGass.size > 0
                # Gas furnace with multi-speed AC modeled as HP in BEopt
                ensure_num_objects(model.getCoilHeatingGass, beopt_key)
                os_val = model.getCoilHeatingGass[0].nominalCapacity.get
            end
            
        elsif beopt_key == 'Coil:Heating:DX:SingleSpeed_Rated Air Flow Rate {m3/s}'
            ensure_num_objects(model.getCoilHeatingDXSingleSpeeds, beopt_key)
            os_val = model.getCoilHeatingDXSingleSpeeds[0].ratedAirFlowRate.get
            
        elsif beopt_key.start_with?('Coil:Heating:DX:MultiSpeed_Speed') and beopt_key.end_with?('Rated Air Flow Rate {m3/s}')
            if model.getCoilHeatingDXMultiSpeeds.size > 0
                ensure_num_objects(model.getCoilHeatingDXMultiSpeeds, beopt_key)
                speed = beopt_key.split(" ")[1].to_i
                os_val = model.getCoilHeatingDXMultiSpeeds[0].stages[speed-1].ratedAirFlowRate.get
            elsif model.getCoilHeatingElectrics.size > 0
                # Electric furnace with multi-speed AC modeled as HP in BEopt
                ensure_num_objects(model.getCoilHeatingElectrics, beopt_key)
                next # no airflow property
            elsif model.getCoilHeatingGass.size > 0
                # Gas furnace with multi-speed AC modeled as HP in BEopt
                ensure_num_objects(model.getCoilHeatingGass, beopt_key)
                next # no airflow property
            end
            
        elsif beopt_key == 'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}'
            ensure_num_objects(model.getCoilCoolingDXSingleSpeeds, beopt_key)
            os_val = model.getCoilCoolingDXSingleSpeeds[0].ratedTotalCoolingCapacity.get
            
        elsif beopt_key.start_with?('Coil:Cooling:DX:MultiSpeed_Speed') and beopt_key.end_with?('Rated Total Cooling Capacity {W}')
            ensure_num_objects(model.getCoilCoolingDXMultiSpeeds, beopt_key)
            speed = beopt_key.split(" ")[1].to_i
            os_val = model.getCoilCoolingDXMultiSpeeds[0].stages[speed-1].grossRatedTotalCoolingCapacity.get
            
        elsif beopt_key == 'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}'
            ensure_num_objects(model.getCoilCoolingDXSingleSpeeds, beopt_key)
            os_val = model.getCoilCoolingDXSingleSpeeds[0].ratedAirFlowRate.get
            
        elsif beopt_key.start_with?('Coil:Cooling:DX:MultiSpeed_Speed') and beopt_key.end_with?('Rated Air Flow Rate {m3/s}')
            ensure_num_objects(model.getCoilCoolingDXMultiSpeeds, beopt_key)
            speed = beopt_key.split(" ")[1].to_i
            os_val = model.getCoilCoolingDXMultiSpeeds[0].stages[speed-1].ratedAirFlowRate.get
            
        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Electric_Living_Heating Design Capacity {W}'
            ensure_num_objects(model.getZoneHVACBaseboardConvectiveElectrics, beopt_key, 2)
            model.getZoneHVACBaseboardConvectiveElectrics.each do |bb|
                next if bb.name.to_s.downcase.include?('basement')
                os_val = bb.nominalCapacity.get
            end
        
        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Electric_Basement_Heating Design Capacity {W}'
            ensure_num_objects(model.getZoneHVACBaseboardConvectiveElectrics, beopt_key, 2)
            model.getZoneHVACBaseboardConvectiveElectrics.each do |bb|
                next if !bb.name.to_s.downcase.include?('basement')
                os_val = bb.nominalCapacity.get
            end
            
        elsif beopt_key == 'ZoneHVAC:WindowAirConditioner_Airflow'
            ensure_num_objects(model.getZoneHVACPackagedTerminalAirConditioners, beopt_key)
            os_val = model.getZoneHVACPackagedTerminalAirConditioners[0].supplyAirFlowRateDuringCoolingOperation.get
            
        elsif beopt_key == 'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}'
            ensure_num_objects(model.getAirTerminalSingleDuctUncontrolleds, beopt_key, 2)
            model.getAirTerminalSingleDuctUncontrolleds.each do |term|
                next if term.name.to_s.downcase.include?('basement')
                os_val = term.maximumAirFlowRate.get
            end
            
        elsif beopt_key == 'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}'
            ensure_num_objects(model.getAirTerminalSingleDuctUncontrolleds, beopt_key, 2)
            model.getAirTerminalSingleDuctUncontrolleds.each do |term|
                next if !term.name.to_s.downcase.include?('basement')
                os_val = term.maximumAirFlowRate.get
            end
            
        elsif beopt_key == 'Fan:OnOff_Maximum Flow Rate {m3/s}'
            model.getFanOnOffs.each do |fan|
                next if !fan.name.to_s.downcase.include?('room ac')
                os_val = fan.maximumFlowRate.get
            end
            
        elsif beopt_key == 'Fan:OnOff_Living_Maximum Flow Rate {m3/s}'
            model.getFanOnOffs.each do |fan|
                next if fan.name.to_s.downcase.include?('basement') or fan.name.to_s.downcase.include?('room ac')
                os_val = fan.maximumFlowRate.get
            end
            
        elsif beopt_key == 'Fan:OnOff_Basement_Maximum Flow Rate {m3/s}'
            model.getFanOnOffs.each do |fan|
                next if !fan.name.to_s.downcase.include?('basement')
                os_val = fan.maximumFlowRate.get
            end
            
        elsif beopt_key == 'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}'
            ensure_num_objects(model.getAirConditionerVariableRefrigerantFlows, beopt_key, 2)
            model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedTotalCoolingCapacity.get
            end
            
        elsif beopt_key == 'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}'
            ensure_num_objects(model.getAirConditionerVariableRefrigerantFlows, beopt_key, 2)
            model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedTotalHeatingCapacity.get
            end
            
        elsif beopt_key == 'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}'
            ensure_num_objects(model.getAirConditionerVariableRefrigerantFlows, beopt_key, 2)
            model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedTotalCoolingCapacity.get
            end
            
        elsif beopt_key == 'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}'
            ensure_num_objects(model.getAirConditionerVariableRefrigerantFlows, beopt_key, 2)
            model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedTotalHeatingCapacity.get
            end
            
        elsif beopt_key == 'Coil:Heating:DX:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}'
            ensure_num_objects(model.getCoilHeatingDXVariableRefrigerantFlows, beopt_key, 2)
            model.getCoilHeatingDXVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedTotalHeatingCapacity.get
            end
            
        elsif beopt_key == 'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}'
            ensure_num_objects(model.getCoilCoolingDXVariableRefrigerantFlows, beopt_key, 2)
            model.getCoilCoolingDXVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedTotalCoolingCapacity.get
            end
            
        elsif beopt_key == 'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}'
            ensure_num_objects(model.getCoilHeatingDXVariableRefrigerantFlows, beopt_key, 2)
            model.getCoilHeatingDXVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedTotalHeatingCapacity.get
            end
            
        elsif beopt_key == 'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}'
            ensure_num_objects(model.getCoilCoolingDXVariableRefrigerantFlows, beopt_key, 2)
            model.getCoilCoolingDXVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedTotalCoolingCapacity.get
            end
            
        elsif beopt_key == 'Coil:Heating:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}'
            ensure_num_objects(model.getCoilHeatingDXVariableRefrigerantFlows, beopt_key, 2)
            model.getCoilHeatingDXVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedAirFlowRate.get
            end
            
        elsif beopt_key == 'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}'
            ensure_num_objects(model.getCoilCoolingDXVariableRefrigerantFlows, beopt_key, 2)
            model.getCoilCoolingDXVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedAirFlowRate.get
            end
            
        elsif beopt_key == 'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}'
            ensure_num_objects(model.getCoilHeatingDXVariableRefrigerantFlows, beopt_key, 2)
            model.getCoilHeatingDXVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedAirFlowRate.get
            end
            
        elsif beopt_key == 'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}'
            ensure_num_objects(model.getCoilCoolingDXVariableRefrigerantFlows, beopt_key, 2)
            model.getCoilCoolingDXVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val = vrf.ratedAirFlowRate.get
            end
            
        elsif beopt_key == 'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Cooling Supply Air Flow Rate {m3/s}'
            ensure_num_objects(model.getZoneHVACTerminalUnitVariableRefrigerantFlows, beopt_key, 2)
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |term|
                next if term.name.to_s.downcase.include?('basement')
                os_val = term.supplyAirFlowRateDuringCoolingOperation.get
            end
            
        elsif beopt_key == 'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Heating Supply Air Flow Rate {m3/s}'
            ensure_num_objects(model.getZoneHVACTerminalUnitVariableRefrigerantFlows, beopt_key, 2)
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |term|
                next if term.name.to_s.downcase.include?('basement')
                os_val = term.supplyAirFlowRateDuringHeatingOperation.get
            end
            
        elsif beopt_key == 'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Cooling Supply Air Flow Rate {m3/s}'
            ensure_num_objects(model.getZoneHVACTerminalUnitVariableRefrigerantFlows, beopt_key, 2)
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |term|
                next if !term.name.to_s.downcase.include?('basement')
                os_val = term.supplyAirFlowRateDuringCoolingOperation.get
            end
            
        elsif beopt_key == 'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Heating Supply Air Flow Rate {m3/s}'
            ensure_num_objects(model.getZoneHVACTerminalUnitVariableRefrigerantFlows, beopt_key, 2)
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |term|
                next if !term.name.to_s.downcase.include?('basement')
                os_val = term.supplyAirFlowRateDuringHeatingOperation.get
            end
            
        elsif beopt_key == 'ZoneHVAC:WindowAirConditioner_Maximum Supply Air Flow Rate {m3/s}'
            ensure_num_objects(model.getZoneHVACPackagedTerminalAirConditioners, beopt_key, 1)
            os_val = model.getZoneHVACPackagedTerminalAirConditioners[0].supplyAirFlowRateDuringCoolingOperation.get
            
        elsif beopt_key == 'ZoneHVAC:Dehumidifier:DX_Rated Water Removal {L/day}'
            ensure_num_objects(model.getZoneHVACDehumidifierDXs, beopt_key, 1)
            os_val = model.getZoneHVACDehumidifierDXs[0].ratedWaterRemoval
            
        elsif beopt_key == 'ZoneHVAC:Dehumidifier:DX_Rated Energy Factor {L/kWh}'
            ensure_num_objects(model.getZoneHVACDehumidifierDXs, beopt_key, 1)
            os_val = model.getZoneHVACDehumidifierDXs[0].ratedEnergyFactor
            
        elsif beopt_key == 'ZoneHVAC:Dehumidifier:DX_Rated Air Flow Rate {m3/s}'
            ensure_num_objects(model.getZoneHVACDehumidifierDXs, beopt_key, 1)
            os_val = model.getZoneHVACDehumidifierDXs[0].ratedAirFlowRate
            
        elsif beopt_key == 'Pump:VariableSpeed_Design Flow Rate {m3/s}'
            model.getPumpVariableSpeeds.each do |pump|
                next if !pump.name.to_s.downcase.include?('boiler')
                os_val = pump.ratedFlowRate.get
            end
        
        elsif beopt_key == 'Boiler:HotWater_Nomimal Capacity {W}'
            ensure_num_objects(model.getBoilerHotWaters, beopt_key, 1)
            os_val = model.getBoilerHotWaters[0].nominalCapacity.get
        
        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Water_Living_U-Factor Times Area Value {W/K}'
            ensure_num_objects(model.getZoneHVACBaseboardConvectiveWaters, beopt_key, 2)
            model.getZoneHVACBaseboardConvectiveWaters.each do |bb|
                next if bb.name.to_s.downcase.include?('basement')
                os_val = bb.heatingCoil.to_CoilHeatingWaterBaseboard.get.uFactorTimesAreaValue.get
            end
        
        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Water_Living_Maximum Water Flow rate {m3/s}'
            ensure_num_objects(model.getZoneHVACBaseboardConvectiveWaters, beopt_key, 2)
            model.getZoneHVACBaseboardConvectiveWaters.each do |bb|
                next if bb.name.to_s.downcase.include?('basement')
                os_val = bb.heatingCoil.to_CoilHeatingWaterBaseboard.get.maximumWaterFlowRate.get
            end
        
        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Water_Basement_U-Factor Times Area Value {W/K}'
            ensure_num_objects(model.getZoneHVACBaseboardConvectiveWaters, beopt_key, 2)
            model.getZoneHVACBaseboardConvectiveWaters.each do |bb|
                next if !bb.name.to_s.downcase.include?('basement')
                os_val = bb.heatingCoil.to_CoilHeatingWaterBaseboard.get.uFactorTimesAreaValue.get
            end
        
        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Water_Basement_Maximum Water Flow rate {m3/s}'
            ensure_num_objects(model.getZoneHVACBaseboardConvectiveWaters, beopt_key, 2)
            model.getZoneHVACBaseboardConvectiveWaters.each do |bb|
                next if !bb.name.to_s.downcase.include?('basement')
                os_val = bb.heatingCoil.to_CoilHeatingWaterBaseboard.get.maximumWaterFlowRate.get
            end
            
        else
            puts "WARNING: Unhandled key: #{beopt_key}."
            next
            
        end
        
        str = ""
        if is_flowrate
            os_val = OpenStudio.convert(os_val,"m^3/s","cfm").get
            beopt_val = OpenStudio.convert(beopt_val,"m^3/s","cfm").get
            str = "#{beopt_key.gsub(flowrate_units,'').strip}: #{beopt_val.round(1)} (BEopt) vs. #{os_val.round(1)} (OS)"
            tolerance = airflow_tolerance
        elsif is_capacity
            os_val = OpenStudio.convert(os_val,"W","Btu/h").get
            beopt_val = OpenStudio.convert(beopt_val,"W","Btu/h").get
            str = "#{beopt_key.gsub(capacity_units,'').strip}: #{beopt_val.round(0)} (BEopt) vs. #{os_val.round(0)} (OS)"
            tolerance = load_total_tolerance
        elsif is_water_removal
            str = "#{beopt_key.gsub(water_removal_units,'').strip}: #{beopt_val.round(1)} (BEopt) vs. #{os_val.round(1)} (OS)"
            tolerance = water_removal_tolerance
        elsif is_energy_factor
            str = "#{beopt_key.gsub(energy_factor_units,'').strip}: #{beopt_val.round(1)} (BEopt) vs. #{os_val.round(1)} (OS)"
            tolerance = energy_factor_tolerance
        elsif is_ua
            str = "#{beopt_key.gsub(ua_units,'').strip}: #{beopt_val.round(0)} (BEopt) vs. #{os_val.round(0)} (OS)"
            tolerance = ua_tolerance
        end
        if print_debug_info
            puts str
        end
        assert_in_delta(beopt_val, os_val, tolerance)
    end
    
    return model
  end
  
  def ensure_num_objects(objects, beopt_key, num=1)
    num_objects = objects.size
    if num_objects != num
        assert_equal(num, num_objects)
    end
  end

end
    