require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class EnergyRatingIndex301Test < MiniTest::Test

  def get_args_hash(hpxml_filename, calc_type)
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/#{hpxml_filename}"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["calc_type"] = calc_type
    args_hash["measures_dir"] = ".."
    args_hash["schemas_dir"] = "./tests/schemas"
    args_hash["hpxml_output_file_path"] = File.join(File.dirname(__FILE__), "#{calc_type} - #{hpxml_filename}")
    args_hash["osm_output_file_path"] = File.join(File.dirname(__FILE__), "#{calc_type} - #{hpxml_filename.gsub(".xml", ".osm")}")
    return args_hash
  end

  def test_hpxml_home
    hpxml = "valid.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_foundation_unconditioned_basement
    hpxml = "valid-foundation-unconditioned-basement.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_foundation_vented_crawlspace
    hpxml = "valid-foundation-vented-crawlspace.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_foundation_slab
    hpxml = "valid-foundation-slab.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_hvac_central_ac_only
    hpxml = "valid-hvac-central-ac-only.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_hvac_furnace_only
    hpxml = "valid-hvac-furnace-only.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_hvac_air_to_air_heat_pump
    hpxml = "valid-hvac-air-to-air-heat-pump.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_hvac_none
    hpxml = "valid-hvac-none.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_hvac_boiler_only
    hpxml = "valid-hvac-boiler-only.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_hvac_elec_resistance_only
    hpxml = "valid-hvac-elec-resistance-only.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  #def test_hpxml_home_hvac_ground_to_air_heat_pump
  #  hpxml = "valid-hvac-ground-to-air-heat-pump.xml"
  #  args_hash = get_args_hash(hpxml, "HERS Reference Home")
  #  expected_num_del_objects = {}
  #  expected_num_new_objects = {}
  #  expected_values = {}
  #  result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  #  args_hash = get_args_hash(hpxml, "HERS Rated Home")
  #  expected_num_del_objects = {}
  #  expected_num_new_objects = {}
  #  expected_values = {}
  #  result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  #end
  
  def test_hpxml_home_hvac_mini_split_heat_pump
    hpxml = "valid-hvac-mini-split-heat-pump.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_home_hvac_room_ac_only
    hpxml = "valid-hvac-room-ac-only.xml"
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  private
  
  def _test_error_or_NA(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = EnergyRatingIndex301.new

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
    measure = EnergyRatingIndex301.new

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
    
    # show_output(result)

    # assert that it ran correctly
    puts result.errors.map{ |x| x.logMessage }
    assert_equal("Success", result.value.valueName)
    #assert(result.info.size == num_infos)
    #assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    #check_num_objects(all_new_objects, expected_num_new_objects, "added")
    #check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
        end
    end
    
    return result
  end

end
