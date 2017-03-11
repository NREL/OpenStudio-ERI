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
            "Dehumid_WaterRemoval_Auto"=>["Unit 1 Final Results","Dehumid WaterReoval"]
           }
  end
  
  def volume_adj_factor(os_above_grade_finished_volume)
    # TODO: For buildings with finished attic space, BEopt calculates a larger volume 
    # than OpenStudio, so we adjust here. Haven't looked into why this occurs.
    beopt_finished_attic_volume = 2644.625
    os_finished_attic_volume = 2124
    living_volume = os_above_grade_finished_volume - os_finished_attic_volume
    return (beopt_finished_attic_volume + living_volume) / (os_finished_attic_volume + living_volume)
  end

=begin
  def test_loads_2story_finished_basement_garage_finished_attic
    args_hash = {}
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
                      }
    _test_measure("SFD_HVACSizing_Load_2story_FB_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true, 4)
  end  
  
  def test_loads_2story_unfinished_basement_garage_finished_attic
    args_hash = {}
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
                      }
    _test_measure("SFD_HVACSizing_Load_2story_UB_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true, 3)
  end  
  
  def test_loads_2story_crawlspace_garage_finished_attic
    args_hash = {}
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
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true, 3)
  end  

  def test_loads_2story_slab_garage_finished_attic
    args_hash = {}
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
                      }
    _test_measure("SFD_HVACSizing_Load_2story_S_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true, 3)
  end  
  
  def test_loads_1story_slab_unfinished_attic_unvented
    args_hash = {}
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
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false, 3)
  end

  def test_loads_1story_slab_unfinished_attic_unvented_no_overhangs
    args_hash = {}
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
                        'Cool Windows' => 2846,
                        'Cool Doors' => 91,
                        'Cool Walls' => 649,
                        'Cool Roofs' => 0,
                        'Cool Floors' => 1011,
                        'Cool Infil Sens' => 817,
                        'Cool Infil Lat' => -1343,
                        'Cool IntGains Sens' => 2547,
                        'Cool IntGains Lat' => 1053,
                        'Heat Load' => 18756,
                        'Cool Load Sens' => 7962,
                        'Cool Load Lat' => 0,
                        'Dehumid Load Sens' => 554,
                        'Dehumid Load Lat' => 549,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_NoOverhangs.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false, 3)
  end

  def test_loads_1story_slab_unfinished_attic_unvented_atlanta
    args_hash = {}
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
                        'Cool Walls' => 949,
                        'Cool Roofs' => 0,
                        'Cool Floors' => 1138,
                        'Cool Infil Sens' => 925,
                        'Cool Infil Lat' => 960,
                        'Cool IntGains Sens' => 2547,
                        'Cool IntGains Lat' => 1053,
                        'Heat Load' => 13110,
                        'Cool Load Sens' => 8100,
                        'Cool Load Lat' => 2014,
                        'Dehumid Load Sens' => 2923,
                        'Dehumid Load Lat' => 3682,
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_Atlanta.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false, 3)
  end
  
  def test_loads_1story_slab_unfinished_attic_unvented_losangeles
    args_hash = {}
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
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_LosAngeles.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false, 3)
  end
  
  def test_loads_1story_pierbeam_unfinished_attic_unvented
    args_hash = {}
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
                      }
    _test_measure("SFD_HVACSizing_Load_1story_PB_UA_Unvented.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false, 3)
  end

  def test_equip_ASHP_one_speed_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_ASHP1_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_ASHP_one_speed_fixedsize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_ASHP1_FixedCapacities.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_ASHP_two_speed_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_ASHP2_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_ASHP_variable_speed_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_ASHPV_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_electric_baseboard_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_BB_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_electric_furnace_and_ac_two_speed_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_EF_AC2_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_electric_furnace_and_ac_variable_speed_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_EF_ACV_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_gas_furnace_and_ac_one_speed_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_GF_AC1_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_gas_furnace_and_ac_one_speed_fixedsize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_GF_AC1_FixedCapacities.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_gas_furnace_and_room_air_conditioner_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_GF_RAC_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_mshp_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_MSHP_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_equip_mshp_and_electric_baseboard_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_MSHP_BB_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
=end  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ProcessHVACSizing.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, apply_volume_adj=false, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessHVACSizing.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)
    
    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

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
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
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
    
    map = beopt_to_os_mapping()
    expected_values.each do |beopt_key, beopt_val|
        os_header = map[beopt_key][0]
        os_key = map[beopt_key][1]
        os_val = 0.0
        result.info.map{ |x| x.logMessage }.each do |info|
            next if not info.split("\n")[0].start_with?(os_header)
            info.split("\n").each do |info_line|
                next if info_line.split('=')[0].strip != os_key
                os_val += info_line.split('=')[1].strip.to_f
            end
        end
        
        if apply_volume_adj
            if ['Heat Infil','Cool Infil Sens','Cool Infil Lat'].include?(beopt_key)
                os_above_grade_finished_volume = Geometry.get_above_grade_finished_volume_from_spaces(model.getSpaces)
                os_val = (os_val * volume_adj_factor(os_above_grade_finished_volume)).round(1)
            end
        end
        
        #puts "#{os_header}: #{os_key}: #{beopt_val} vs. #{os_val}"
        
        # TODO: Tighten these tolerances eventually
        if os_key.downcase.include?("airflow")
            assert_in_delta(beopt_val, os_val, 100) # cfm
        elsif os_header.downcase.include?("results")
            # Aggregate results
            assert_in_delta(beopt_val, os_val, 1000) # Btu/hr
        else
            # Individual components
            assert_in_delta(beopt_val, os_val, 250) # Btu/hr
        end
    end
    
    return model
  end

end
    