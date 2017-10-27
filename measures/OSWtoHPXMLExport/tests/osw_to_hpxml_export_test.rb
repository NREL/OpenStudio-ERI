require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require 'zip'
require 'parallel'

class OSWtoHPXMLExportTest < MiniTest::Test

=begin
  def test_valid_xml
    args_hash = {}
    args_hash["schemas_dir"] = "../../hpxml_schemas"
    args_hash["measures_dir"] = "../../resources/measures"
    Dir[File.join(File.dirname(__FILE__), "*.osw")].each do |osw_file_path| # one osw file in tests directory at a time
    # Parallel.each(Dir[File.join(File.dirname(__FILE__), "*.osw")], in_threads: 1) do |osw_file_path| # parallelized osw files in tests directory (doesn't work on ci machine?)
      osw_file_path = File.join(".", File.join(File.basename(File.dirname(__FILE__)), File.basename(osw_file_path)))
    # Parallel.each(get_resstock_osw_file_paths, in_threads: 3) do |osw_file_path| # parallelized osw files in resstock directory (doesn't work on ci machine?)
      args_hash["osw_file_path"] = osw_file_path
    #  next if File.exist? File.join(File.dirname(__FILE__), "#{File.basename osw_file_path, ".*"}.xml")
      expected_num_del_objects = {}
      expected_num_new_objects = {}
      expected_values = {}
      result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    end
  end
=end
  
  private
  
  def get_resstock_osw_file_paths

    Zip.warn_invalid_date = false
    FileUtils.rm_rf(File.join(File.dirname(__FILE__), "data_point"))
    osw_file_paths = []
    Zip::File.open(File.join(File.dirname(__FILE__), "resstock_dsgrid_cr3_localResults.zip")) do |zip|
      zip.each do |entry|
        next unless entry.name.end_with? ".zip"
        f_path = File.join(File.dirname(__FILE__), "data_point", entry.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        entry.extract(f_path)
        Zip::File.open(f_path) do |dp_zip|
          dp_zip.each do |dp_entry|
            next unless dp_entry.name.end_with? ".osw"
            dp_path = File.join(File.dirname(__FILE__), "data_point", File.dirname(entry.name), dp_entry.name)
            FileUtils.mkdir_p(File.dirname(dp_path))
            FileUtils.rm_rf(dp_path)
            dp_entry.extract(dp_path)
            text = File.read(dp_path)
            if text.include? "ResidentialApplianceClothesDryerElectric" or text.include? "ResidentialApplianceClothesDryerFuel"
            else
              next
            end
            new_contents = text.gsub(/weather_file_name.*epw/, 'weather_file_name" : "USA_CO_Denver_Intl_AP_725650_TMY3.epw')
            new_contents = new_contents.gsub(/weather_directory.*weather/, 'weather_directory" : "./resources')
            new_contents = new_contents.gsub('"num_occ" : "auto",', '"num_occ" : "auto",' + "\n" + '"occ_gain" : "384",' + "\n" + '"sens_frac" : "0.573",' + "\n" + '"lat_frac" : "0.427",')
            new_contents = new_contents.gsub('"aspect_ratio" : "1.333",', '"aspect_ratio" : "1.333",' + "\n" + '"front_area" : "0",' + "\n" + '"back_area" : "0",' + "\n" + '"left_area" : "0",' + "\n" + '"right_area" : "0",')
            new_contents = new_contents.gsub(/ufactor.*"/, 'ufactor_back" : "0.37",' + "\n" + '"ufactor_front" : "0.37",' + "\n" + '"ufactor_left" : "0.37",' + "\n" + '"ufactor_right" : "0.37"')
            new_contents = new_contents.gsub(/shgc.*"/, 'shgc_back" : "0.3",' + "\n" + '"shgc_front" : "0.3",' + "\n" + '"shgc_left" : "0.3",' + "\n" + '"shgc_right" : "0.3"')
            new_contents = new_contents.gsub('door_uvalue', 'door_ufactor')
            new_contents = new_contents.gsub('cw_', '')
            new_contents = new_contents.gsub('cd_', '')
            new_contents = new_contents.gsub('"cfl_eff" : "55",', '"cfl_eff" : "55",' + "\n" + '"energy_use_exterior" : "300",' + "\n" + '"energy_use_garage" : "100",' + "\n" + '"energy_use_interior" : "900",' + "\n" + '"option_type" : "Lamp Fractions",')
            new_contents = new_contents.gsub('"mult" : "0.5",
            "weekday_sch" : "0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",', '"mult" : "0.5",
            "weekday_sch" : "0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",' + "\n" + '"energy_use" : "2000",' + "\n" + '"lat_frac" : "0.021",' + "\n" + '"option_type" : "Multiplier",' + "\n" + '"sens_frac" : "0.093",')
            new_contents = new_contents.gsub('"mult" : "1.0",
            "weekday_sch" : "0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",', '"mult" : "1.0",
            "weekday_sch" : "0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",' + "\n" + '"energy_use" : "2000",' + "\n" + '"lat_frac" : "0.021",' + "\n" + '"option_type" : "Multiplier",' + "\n" + '"sens_frac" : "0.093",')
            new_contents = new_contents.gsub('"mult" : "2.0",
            "weekday_sch" : "0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",', '"mult" : "2.0",
            "weekday_sch" : "0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",' + "\n" + '"energy_use" : "2000",' + "\n" + '"lat_frac" : "0.021",' + "\n" + '"option_type" : "Multiplier",' + "\n" + '"sens_frac" : "0.093",')
            File.open(dp_path.gsub("measures.osw", File.basename(File.dirname(entry.name)) + ".osw"), "w") {|file| file.puts new_contents }
            osw_file_paths << File.join(File.basename(File.dirname(__FILE__)), "data_point", File.dirname(entry.name), File.basename(File.dirname(entry.name)) + ".osw")
          end
        end
      end
    end
    return osw_file_paths
  end
  
  def _test_error_or_NA(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = OSWtoHPXMLExport.new

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
    measure = OSWtoHPXMLExport.new

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
    assert_equal("Success", result.value.valueName)
    # assert(result.info.size > 0)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    # check_num_objects(all_new_objects, expected_num_new_objects, "added")
    # check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get

        end
    end
    
    return result
  end

end
