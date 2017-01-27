require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialMultifamilyGeometryTest < MiniTest::Test

  def test_error_existing_geometry
    args_hash = {}
    result = _test_error("MF_8units_1story_SL_Denver.osm", args_hash) 
    assert_includes(result.errors.map{ |x| x.logMessage }, "Starting model is not empty.")
  end

  def test_argument_error_crawl_height_invalid
    args_hash = {}
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    args_hash["foundation_height"] = 0
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "The crawlspace height can be set between 1.5 and 5 ft.")
  end  
  
  def test_argument_error_aspect_ratio_invalid
    args_hash = {}
    args_hash["unit_aspect_ratio"] = -1.0
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Invalid aspect ratio entered.")
  end
  
  def test_error_no_corr
    args_hash = {}
    args_hash["corr_width"] = -1
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Invalid corridor width entered.")
  end  
  
  def test_warning_uneven_units_per_floor_with_interior_corr
    args_hash = {}
    args_hash["num_units_per_floor"] = 3
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>2, "Surface"=>18, "ThermalZone"=>1+2, "Space"=>1+2}
    expected_values = {"FinishedFloorArea"=>900*2, "BuildingHeight"=>8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end
  
  def test_warning_balc_but_no_inset
    args_hash = {}
    args_hash["balc_depth"] = 6
    args_hash["corr_pos"] = "None"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>2, "Surface"=>12, "ThermalZone"=>2, "Space"=>2}
    expected_values = {"FinishedFloorArea"=>900*2, "BuildingHeight"=>8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end

  def test_two_story_double_exterior
    args_hash = {}
    args_hash["building_num_floors"] = 2
    args_hash["num_units_per_floor"] = 4
    args_hash["corr_pos"] = "Double Exterior"
    args_hash["inset_width"] = 8
    args_hash["inset_depth"] = 6
    args_hash["balc_depth"] = 6
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>2*4, "Surface"=>68, "ThermalZone"=>2*4, "Space"=>2*4, "ShadingSurfaceGroup"=>12, "ShadingSurface"=>12}
    expected_values = {"FinishedFloorArea"=>900*2*4, "BuildingHeight"=>2*8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end       
  
  def test_multiplex_right_inset
    args_hash = {}
    args_hash["building_num_floors"] = 8
    args_hash["num_units_per_floor"] = 6
    args_hash["inset_width"] = 8
    args_hash["inset_depth"] = 6
    args_hash["foundation_type"] = Constants.UnfinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>8*6, "Surface"=>538, "ThermalZone"=>8*6+1+1, "Space"=>8*6+1+8}
    expected_values = {"FinishedFloorArea"=>900*8*6, "UnfinishedBasementHeight"=>8, "UnfinishedBasementFloorArea"=>6*900+3*21.77*10, "BuildingHeight"=>8+8*8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)   
  end  
  
  def test_multiplex_left_inset
    args_hash = {}
    args_hash["building_num_floors"] = 8
    args_hash["num_units_per_floor"] = 6
    args_hash["inset_width"] = 8
    args_hash["inset_depth"] = 6
    args_hash["inset_pos"] = "Left"
    args_hash["balc_depth"] = 6
    args_hash["foundation_type"] = Constants.UnfinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>8*6, "Surface"=>538, "ThermalZone"=>8*6+1+1, "Space"=>8*6+1+8, "ShadingSurface"=>8*6, "ShadingSurfaceGroup"=>8*6}
    expected_values = {"FinishedFloorArea"=>900*8*6, "UnfinishedBasementHeight"=>8, "UnfinishedBasementFloorArea"=>6*900+3*21.77*10, "BuildingHeight"=>8+8*8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values) 
  end    
  
  def test_crawl_single_exterior
    args_hash = {}
    args_hash["building_num_floors"] = 2
    args_hash["num_units_per_floor"] = 12
    args_hash["corr_pos"] = "Single Exterior (Front)"
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>2*12, "Surface"=>194, "ThermalZone"=>2*12+1, "Space"=>2*12+1, "ShadingSurface"=>2, "ShadingSurfaceGroup"=>2}
    expected_values = {"FinishedFloorArea"=>900*2*12, "CrawlspaceHeight"=>3, "CrawlspaceFloorArea"=>12*900, "BuildingHeight"=>3+2*8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end  
  
  def test_crawlspace_double_loaded_corr
    args_hash = {}
    args_hash["num_units_per_floor"] = 4
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>1*4, "Surface"=>52, "ThermalZone"=>1*4+1+1, "Space"=>1*4+1+1}
    expected_values = {"FinishedFloorArea"=>900*1*4, "CrawlspaceHeight"=>3, "CrawlspaceFloorArea"=>4*900, "BuildingHeight"=>3+8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)      
  end  
  
  def test_ufbasement_double_loaded_corr
    args_hash = {}
    args_hash["num_units_per_floor"] = 4
    args_hash["foundation_type"] = Constants.UnfinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>1*4, "Surface"=>52, "ThermalZone"=>1*4+1+1, "Space"=>1*4+1+1}
    expected_values = {"FinishedFloorArea"=>900*1*4, "UnfinishedBasementHeight"=>8, "UnfinishedBasementFloorArea"=>4*900+2*21.21*10, "BuildingHeight"=>8+8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)      
  end     
  
  def test_zone_mult_front_units_only
    args_hash = {}
    args_hash["num_units_per_floor"] = 8
    args_hash["corr_width"] = 0
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>3, "Surface"=>18, "ThermalZone"=>3, "Space"=>3}
    expected_values = {"FinishedFloorArea"=>900*3, "BuildingHeight"=>8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end  
  
  def test_zone_mult_with_rear_units_even
    args_hash = {}
    args_hash["num_units_per_floor"] = 8
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>6, "Surface"=>48, "ThermalZone"=>6+1, "Space"=>6+1}
    expected_values = {"FinishedFloorArea"=>900*6, "BuildingHeight"=>8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end
  
  def test_zone_mult_with_rear_units_odd
    args_hash = {}
    args_hash["num_units_per_floor"] = 9
    args_hash["corr_pos"] = "Double Exterior"
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>6, "Surface"=>36, "ThermalZone"=>6, "Space"=>6, "ShadingSurface"=>2, "ShadingSurfaceGroup"=>2}
    expected_values = {"FinishedFloorArea"=>900*6, "BuildingHeight"=>8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end
  
  def test_floor_mult
    args_hash = {}
    args_hash["building_num_floors"] = 12
    args_hash["num_units_per_floor"] = 8
    args_hash["use_floor_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>24, "Surface"=>288, "ThermalZone"=>25, "Space"=>36}
    expected_values = {"FinishedFloorArea"=>900*24, "BuildingHeight"=>12*8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end
  
  def test_one_unit_per_floor_with_rear_units
    args_hash = {}
    args_hash["num_units_per_floor"] = 1
    result = _test_error(nil, args_hash) 
    assert_includes(result.errors.map{ |x| x.logMessage }, "Specified building as having rear units, but didn't specify enough units.")
  end
  
  def test_two_units_per_floor_with_rear_units
    args_hash = {}
    args_hash["building_num_floors"] = 4
    args_hash["num_units_per_floor"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>8, "Surface"=>72, "ThermalZone"=>8+1, "Space"=>12}
    expected_values = {"FinishedFloorArea"=>900*8, "BuildingHeight"=>4*8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end  
  
  def test_one_unit_per_floor_with_no_rear_units
    args_hash = {}
    args_hash["building_num_floors"] = 4
    args_hash["num_units_per_floor"] = 1
    args_hash["corr_pos"] = "None"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>4, "Surface"=>24, "ThermalZone"=>4, "Space"=>4}
    expected_values = {"FinishedFloorArea"=>900*4, "BuildingHeight"=>4*8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end    
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = CreateResidentialMultifamilyGeometry.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = CreateResidentialMultifamilyGeometry.new

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

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["PortList", "Node", "ZoneEquipmentList", "SizingZone", "ZoneHVACEquipmentList", "ScheduleTypeLimits", "ScheduleDay", "ScheduleRuleset", "Building"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = {"FinishedFloorArea"=>0, "UnfinishedBasementFloorArea"=>0, "CrawlspaceFloorArea"=>0, "UnfinishedBasementHeight"=>0, "CrawlspaceHeight"=>0}
    new_spaces = []
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Space"
                if new_object.name.to_s.start_with?(Constants.UnfinishedBasementFoundationType)
                    actual_values["UnfinishedBasementHeight"] = Geometry.get_building_height([new_object])
                    actual_values["UnfinishedBasementFloorArea"] += OpenStudio::convert(new_object.floorArea,"m^2","ft^2").get
                elsif new_object.name.to_s.start_with?(Constants.CrawlFoundationType)
                    actual_values["CrawlspaceHeight"] = Geometry.get_building_height([new_object])
                    actual_values["CrawlspaceFloorArea"] += OpenStudio::convert(new_object.floorArea,"m^2","ft^2").get
                end
                if Geometry.space_is_finished(new_object)
                    actual_values["FinishedFloorArea"] += OpenStudio::convert(new_object.floorArea,"m^2","ft^2").get
                end
                new_spaces << new_object
            end
        end
    end
    if new_spaces.any? {|new_space| new_space.name.to_s.start_with?(Constants.UnfinishedBasementFoundationType)}
        assert_in_epsilon(expected_values["UnfinishedBasementHeight"], actual_values["UnfinishedBasementHeight"], 0.01)
        assert_in_epsilon(expected_values["UnfinishedBasementFloorArea"], actual_values["UnfinishedBasementFloorArea"], 0.01)
    end
    if new_spaces.any? {|new_space| new_space.name.to_s.start_with?(Constants.CrawlFoundationType)}
        assert_in_epsilon(expected_values["CrawlspaceHeight"], actual_values["CrawlspaceHeight"], 0.01)
        assert_in_epsilon(expected_values["CrawlspaceFloorArea"], actual_values["CrawlspaceFloorArea"], 0.01)
    end 
    assert_in_epsilon(expected_values["FinishedFloorArea"], actual_values["FinishedFloorArea"], 0.01)
    assert_in_epsilon(expected_values["BuildingHeight"], Geometry.get_building_height(new_spaces), 0.01)
    
    return model
  end  
  
end
