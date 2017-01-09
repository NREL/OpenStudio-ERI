require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialSingleFamilyAttachedGeometryTest < MiniTest::Test

  def test_error_existing_geometry
    args_hash = {}
    result = _test_error("SFA_4units_1story_FB_UA_Denver.osm", args_hash)
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
  
  def test_two_story_fourplex_front_units
    args_hash = {}
    args_hash["building_num_floors"] = 2
    args_hash["num_units"] = 4
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>4, "Surface"=>92, "ThermalZone"=>2*4+1, "Space"=>(2+1)*4+1}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>3.75}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)        
  end  
  
  def test_two_story_fourplex_rear_units
    args_hash = {}
    args_hash["building_num_floors"] = 2
    args_hash["num_units"] = 4
    args_hash["has_rear_units"] = "true"
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType    
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>4, "Surface"=>88, "ThermalZone"=>2*4+1, "Space"=>(2+1)*4+1}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>3.75}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end  

  def test_ufbasement
    args_hash = {}
    args_hash["num_units"] = 4
    args_hash["foundation_type"] = Constants.UnfinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>4, "Surface"=>62, "ThermalZone"=>4+1+1, "Space"=>4+1+1}
    expected_values = {"UnfinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5.30}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values) 
  end  
  
  def test_crawl
    args_hash = {}
    args_hash["num_units"] = 4
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>4, "Surface"=>62, "ThermalZone"=>4+1+1, "Space"=>4+1+1}
    expected_values = {"CrawlspaceHeight"=>3, "UnfinishedAtticHeight"=>5.30}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values) 
  end  
  
  def test_zone_mult_front_units_only
    args_hash = {}
    args_hash["num_units"] = 8
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>3, "Surface"=>58, "ThermalZone"=>4, "Space"=>4}
    expected_values = {"UnfinishedAtticHeight"=>5.30}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end  
  
  def test_zone_mult_with_rear_units_even
    args_hash = {}
    args_hash["num_units"] = 8
    args_hash["has_rear_units"] = "true"
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>6, "Surface"=>68, "ThermalZone"=>6+1, "Space"=>6+1}
    expected_values = {"UnfinishedAtticHeight"=>5.30}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end
  
  def test_zone_mult_with_rear_units_odd
    args_hash = {}
    args_hash["num_units"] = 9
    args_hash["has_rear_units"] = "true"
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>6, "Surface"=>73, "ThermalZone"=>6+1, "Space"=>6+1}
    expected_values = {"UnfinishedAtticHeight"=>5.30}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_one_unit_per_floor_with_rear_units
    args_hash = {}
    args_hash["num_units"] = 1
    args_hash["has_rear_units"] = "true"
    result = _test_error(nil, args_hash) 
    assert_includes(result.errors.map{ |x| x.logMessage }, "Specified building as having rear units, but didn't specify enough units.")    
  end
  
  def test_fourplex_finished_hip_roof
    args_hash = {}
    args_hash["num_units"] = 4
    args_hash["attic_type"] = Constants.FinishedAtticType
    args_hash["roof_type"] = Constants.RoofTypeHip
    args_hash["roof_pitch"] = "12:12"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>4, "Surface"=>44, "ThermalZone"=>4, "Space"=>4+4}
    expected_values = {"FinishedAtticHeight"=>10.60}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end
  
  def test_fourplex_finished_hip_roof_with_rear_units
    args_hash = {}
    args_hash["num_units"] = 4
    args_hash["has_rear_units"] = "true"
    args_hash["attic_type"] = Constants.FinishedAtticType
    args_hash["roof_type"] = Constants.RoofTypeHip
    args_hash["roof_pitch"] = "12:12"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>4, "Surface"=>44, "ThermalZone"=>4, "Space"=>4+4}
    expected_values = {"FinishedAtticHeight"=>10.60}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = CreateResidentialSingleFamilyAttachedGeometry.new

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
    measure = CreateResidentialSingleFamilyAttachedGeometry.new

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

    actual_values = {"FinishedBasementHeight"=>0, "UnfinishedBasementHeight"=>0, "CrawlspaceHeight"=>0, "UnfinishedAtticHeight"=>0, "FinishedAtticHeight"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Space"
                if new_object.name.to_s.start_with?(Constants.FinishedBasementFoundationType)
                    actual_values["FinishedBasementHeight"] = Geometry.get_building_height([new_object])
                elsif new_object.name.to_s.start_with?(Constants.UnfinishedBasementFoundationType)
                    actual_values["UnfinishedBasementHeight"] = Geometry.get_building_height([new_object])
                elsif new_object.name.to_s.start_with?(Constants.CrawlFoundationType)
                    actual_values["CrawlspaceHeight"] = Geometry.get_building_height([new_object])
                elsif new_object.name.to_s.start_with?(Constants.UnfinishedAtticType)
                    actual_values["UnfinishedAtticHeight"] = Geometry.get_building_height([new_object])
                elsif new_object.name.to_s.start_with?(Constants.FinishedAtticType)
                    actual_values["FinishedAtticHeight"] = Geometry.get_building_height([new_object])
                end
            end
        end
    end
    if actual_values["FinishedBasementHeight"] > 0
        assert_in_epsilon(expected_values["FinishedBasementHeight"], actual_values["FinishedBasementHeight"], 0.01)
    end
    if actual_values["UnfinishedBasementHeight"] > 0
        assert_in_epsilon(expected_values["UnfinishedBasementHeight"], actual_values["UnfinishedBasementHeight"], 0.01)
    end
    if actual_values["CrawlspaceHeight"] > 0
        assert_in_epsilon(expected_values["CrawlspaceHeight"], actual_values["CrawlspaceHeight"], 0.01)
    end
    if actual_values["UnfinishedAtticHeight"] > 0
        assert_in_epsilon(expected_values["UnfinishedAtticHeight"], actual_values["UnfinishedAtticHeight"], 0.01)
    end
    if actual_values["FinishedAtticHeight"] > 0
        assert_in_epsilon(expected_values["FinishedAtticHeight"], actual_values["FinishedAtticHeight"], 0.01)
    end
    
    return model
  end  
  
end
