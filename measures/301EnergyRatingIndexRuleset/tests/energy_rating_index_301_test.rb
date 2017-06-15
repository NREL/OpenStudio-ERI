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
    #args_hash["output_file_path"] = File.join(File.dirname(__FILE__), "#{calc_type} - #{hpxml_filename}")
    return args_hash
  end

  def test_hpxml_reference_home
    args_hash = get_args_hash("valid.xml", "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_rated_home
    args_hash = get_args_hash("valid.xml", "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_reference_home_unconditioned_basement
    args_hash = get_args_hash("valid-unconditioned-basement.xml", "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_rated_home_unconditioned_basement
    args_hash = get_args_hash("valid-unconditioned-basement.xml", "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_reference_home_vented_crawlspace
    args_hash = get_args_hash("valid-vented-crawlspace.xml", "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_rated_home_vented_crawlspace
    args_hash = get_args_hash("valid-vented-crawlspace.xml", "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_reference_home_slab
    args_hash = get_args_hash("valid-slab.xml", "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_hpxml_rated_home_slab
    args_hash = get_args_hash("valid-slab.xml", "HERS Rated Home")
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
    
    show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    #assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
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
