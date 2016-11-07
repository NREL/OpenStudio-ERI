require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialSingleFamilyDetachedGeometryTest < MiniTest::Test

  def test_error_existing_geometry
    args_hash = {}
    result = _test_error("singlefamily_detached.osm", args_hash)  
    assert_includes(result.errors.map{ |x| x.logMessage }, "Starting model is not empty.")
  end
  
  def test_argument_error_aspect_ratio_invalid
    args_hash = {}
    args_hash["aspect_ratio"] = -1.0
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Invalid aspect ratio entered.")
  end
  
  def test_argument_error_crawl_height_invalid
    args_hash = {}
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    args_hash["foundation_height"] = 0
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "The crawlspace height can be set between 1.5 and 5 ft.")
  end  
  
  def test_argument_error_pierbeam_height_invalid
    args_hash = {}
    args_hash["foundation_type"] = Constants.PierBeamFoundationType
    args_hash["foundation_height"] = 0
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "The pier & beam height can be set between 0.5 and 8 ft.")
  end  
  
  def test_argument_error_num_floors_invalid
    args_hash = {}
    args_hash["num_floors"] = 7
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Too many floors.")
  end
  
  def test_argument_error_garage_protrusion_invalid
    args_hash = {}
    args_hash["garage_protrusion"] = 2
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Invalid garage protrusion value entered.")
  end
  
  def test_argument_error_hip_roof_and_garage_protrudes
    args_hash = {}
    args_hash["garage_protrusion"] = 0.5
    args_hash["roof_type"] = Constants.RoofTypeHip
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Cannot handle protruding garage and hip roof.")
  end
  
  def test_argument_error_living_and_garage_ridges_are_parallel
    args_hash = {}
    args_hash["garage_protrusion"] = 0.5
    args_hash["aspect_ratio"] = 0.75
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Cannot handle protruding garage and attic ridge running from front to back.")
  end
  
  def test_argument_error_garage_width_exceeds_living_width
    args_hash = {}
    args_hash["garage_width"] = 10000
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Invalid living space and garage dimensions.")  
  end
  
  def test_argument_error_garage_depth_exceeds_living_depth
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["garage_depth"] = 10000
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Invalid living space and garage dimensions.")  
  end
  
  def test_change_garage_pitch_when_garage_ridge_higher_than_house_ridge
    num_units = 1
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_protrusion"] = 0.5
    args_hash["garage_width"] = 40
    args_hash["garage_depth"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>26, "ThermalZone"=>3, "Space"=>4}
    expected_values = {"GarageAtticHeight"=>35.21/2*0.5, "UnfinishedAtticHeight"=>8.8}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4, 1)    
  end
  
  def test_fbasement
    num_units = 1
    args_hash = {}
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>23, "ThermalZone"=>3, "Space"=>4}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>4.56}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)     
  end

  def test_ufbasement
    num_units = 1
    args_hash = {}
    args_hash["foundation_type"] = Constants.UnfinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>23, "ThermalZone"=>3, "Space"=>4}
    expected_values = {"UnfinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5.59}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)   
  end
  
  def test_crawlspace
    num_units = 1
    args_hash = {}
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>23, "ThermalZone"=>3, "Space"=>4}
    expected_values = {"CrawlspaceHeight"=>3, "UnfinishedAtticHeight"=>5.59}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)   
  end
  
  def test_pierandbeam
    num_units = 1
    args_hash = {}
    args_hash["foundation_type"] = Constants.PierBeamFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>23, "ThermalZone"=>3, "Space"=>4}
    expected_values = {"CrawlspaceHeight"=>3, "UnfinishedAtticHeight"=>5.59}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)   
  end  
  
  def test_hip_finished_attic
    num_units = 1
    args_hash = {}
    args_hash["attic_type"] = Constants.FinishedAtticType
    args_hash["roof_type"] = Constants.RoofTypeHip
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>17, "ThermalZone"=>1, "Space"=>3}
    expected_values = {"FinishedAtticHeight"=>5.59}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end
  
  def test_onestory_fbasement_hasgarage_noprotrusion_garageright_gableroof
    num_units = 1
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>28, "ThermalZone"=>4, "Space"=>4}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>6.22}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_onestory_fbasement_hasgarage_halfprotrusion_garageright_gableroof
    num_units = 1
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    args_hash["garage_protrusion"] = 0.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>34, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5.91, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_onestory_fbasement_hasgarage_fullprotrusion_garageright_gableroof
    num_units = 1
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    args_hash["garage_protrusion"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>28, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5.59, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_twostory_fbasement_hasgarage_noprotrusion_garageright_garagetobackwall_gableroof
    num_units = 1
    args_hash = {}
    args_hash["garage_width"] = 10
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>30, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end   
  
  def test_twostory_fbasement_hasgarage_noprotrusion_garageright_gableroof
    num_units = 1
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>34, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5.08, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_twostory_fbasement_hasgarage_halfprotrusion_garageright_gableroof
    num_units = 1
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    args_hash["garage_protrusion"] = 0.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>41, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>4.69, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_twostory_fbasement_hasgarage_fullprotrusion_garageright_gableroof
    num_units = 1
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    args_hash["garage_protrusion"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>37, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>4.28, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)   
  end   
  
  def test_onestory_fbasement_hasgarage_noprotrusion_garageleft_gableroof
    num_units = 1
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>28, "ThermalZone"=>4, "Space"=>4}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>6.22, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)   
  end  
  
  def test_onestory_fbasement_hasgarage_halfprotrusion_garageleft_gableroof
    num_units = 1
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    args_hash["garage_protrusion"] = 0.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>34, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5.91, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_onestory_fbasement_hasgarage_fullprotrusion_garageleft_gableroof
    num_units = 1
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    args_hash["garage_protrusion"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>28, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5.59, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end   
  
  def test_twostory_fbasement_hasgarage_noprotrusion_garageleft_gableroof
    num_units = 1
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>34, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5.08, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5) 
  end  
  
  def test_twostory_fbasement_hasgarage_halfprotrusion_garageleft_gableroof
    num_units = 1
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    args_hash["garage_protrusion"] = 0.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>41, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>4.69, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_twostory_fbasement_hasgarage_fullprotrusion_garageleft_gableroof
    num_units = 1
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType
    args_hash["garage_protrusion"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>37, "ThermalZone"=>4, "Space"=>5}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>4.28, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end

  def test_twostory_slab_hasgarage_noprotrusion_garageright_hiproof
    num_units = 1
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["roof_type"] = Constants.RoofTypeHip
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>26, "ThermalZone"=>3, "Space"=>4}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>5.91, "GarageAtticHeight"=>3}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_gable_ridge_front_to_back
    num_units = 1
    args_hash = {}
    args_hash["aspect_ratio"] = 0.75
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>17, "ThermalZone"=>2, "Space"=>3}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>6.84}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end
  
  def test_hip_ridge_front_to_back
    num_units = 1
    args_hash = {}
    args_hash["aspect_ratio"] = 0.75
    args_hash["roof_type"] = Constants.RoofTypeHip
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>num_units, "Surface"=>17, "ThermalZone"=>2, "Space"=>3}
    expected_values = {"FinishedBasementHeight"=>8, "UnfinishedAtticHeight"=>6.84}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end  
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = CreateResidentialSingleFamilyDetachedGeometry.new

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
    measure = CreateResidentialSingleFamilyDetachedGeometry.new

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

    actual_values = {"GarageAtticHeight"=>0, "FinishedBasementHeight"=>0, "UnfinishedBasementHeight"=>0, "CrawlspaceHeight"=>0, "UnfinishedAtticHeight"=>0, "FinishedAtticHeight"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Space"
                if new_object.name.to_s.start_with?(Constants.GarageAtticSpace)
                    actual_values["GarageAtticHeight"] = Geometry.get_building_height([new_object])
                elsif new_object.name.to_s.start_with?(Constants.FinishedBasementFoundationType)
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
    if actual_values["GarageAtticHeight"] > 0
        assert_in_epsilon(expected_values["GarageAtticHeight"], actual_values["GarageAtticHeight"], 0.01)
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
