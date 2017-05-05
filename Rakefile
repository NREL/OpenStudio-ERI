require 'bundler'
Bundler.setup

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

require 'pp'
require 'colored'
require 'json'

# change the file: users/username/.bcl/config.yml
# to the ID of the BCL group you want your measures to go into
# get the group id number from the URL of the group on BCL
# https://bcl.nrel.gov/node/37347 - the group ID here is 37347
# you must be an administrator or editor member of a group to
# upload content to that group

# Get latest installed version of openstudio.exe
os_clis = Dir["C:/openstudio-*/bin/openstudio.exe"] + Dir["/usr/bin/openstudio"] + Dir["/usr/local/bin/openstudio"]
if os_clis.size == 0
    puts "ERROR: Could not find the openstudio binary. You may need to install the OpenStudio Command Line Interface."
    exit
end
os_cli = os_clis[-1]

namespace :measures do
  desc 'Generate measures to prepare for upload to BCL '
  task :generate do
    require 'bcl'
    name_hash = replace_name_in_measure_xmls()
    # verify staged directory exists
    FileUtils.mkdir_p('./staged')
    dirs = Dir.glob('./measures/*')
    dirs.each do |dir|
      next if dir.include?('Rakefile')
      current_d = Dir.pwd
      measure_name = File.basename(dir)
      puts "Generating #{measure_name}"

      Dir.chdir(dir)
      # puts Dir.pwd

      destination = "../../staged/#{measure_name}.tar.gz"
      FileUtils.rm(destination) if File.exist?(destination)
      files = Pathname.glob('**/*')
      files.each do |f|
        puts "  #{f}"
      end
      paths = []
      files.each do |file|
        paths << file.to_s
      end

      BCL.tarball(destination, paths)
      Dir.chdir(current_d)
    end
    revert_name_in_measure_xmls(name_hash)
  end

  desc 'Push generated measures to the BCL group defined in .bcl/config.yml'
  task :push do
    require 'bcl'
    # grab all the tar files and push to bcl
    measures = []
    paths = Pathname.glob('./staged/*.tar.gz')
    paths.each do |path|
      puts path
      measures << path.to_s
    end
    bcl = BCL::ComponentMethods.new
    bcl.login
    bcl.push_contents(measures, true, 'nrel_measure')
  end

  desc 'update generated measures on the BCL'
  task :update do
    require 'bcl'
    # grab all the tar files and push to bcl
    measures = []
    paths = Pathname.glob('./staged/*.tar.gz')
    paths.each do |path|
      puts path
      measures << path.to_s
    end
    bcl = BCL::ComponentMethods.new
    bcl.login
    bcl.update_contents(measures, true)
  end

  desc 'test the BCL login credentials defined in .bcl/config.yml'
  task :test_bcl_login do
    require 'bcl'
    bcl = BCL::ComponentMethods.new
    bcl.login
  end

  desc 'create JSON metadata files'
  task :create_measure_jsons do
    require 'bcl'
    bcl = BCL::ComponentMethods.new

    Dir['./**/measure.rb'].each do |m|
      puts "Parsing #{m}"
      j = bcl.parse_measure_file(nil, m)
      m_j = "#{File.join(File.dirname(m), File.basename(m, '.*'))}.json"
      puts "Writing #{m_j}"
      File.open(m_j, 'w') { |f| f << JSON.pretty_generate(j) }
    end
  end

  desc 'make csv file of measures'
  task create_measure_csv: [:create_measure_jsons] do
    require 'CSV'
    require 'bcl'

    b = BCL::ComponentMethods.new
    new_csv_file = './measures_spreadsheet.csv'
    FileUtils.rm_f(new_csv_file) if File.exist?(new_csv_file)
    csv = CSV.open(new_csv_file, 'w')
    Dir.glob('./**/measure.json').each do |file|
      puts "Parsing Measure JSON for CSV #{file}"
      json = JSON.parse(File.read(file), symbolize_names: true)
      b.translate_measure_hash_to_csv(json).each { |r| csv << r }
    end

    csv.close
  end
end # end the :measures namespace

namespace :test do

  desc 'Run unit tests for all measures'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['measures/*/tests/*.rb']
    t.warning = false
    t.verbose = true
  end
  
  desc 'regenerate test osm files from osw files'
  task :regenerate_osms do

    num_tot = 0
    num_success = 0
    
    osw_path = File.expand_path("../test/osw_files/", __FILE__)
  
    # Generate hash that maps osw's to measures
    osw_map = {}
    #measures = ["ResidentialHVACSizing"] # Use this to specify individual measures (instead of all measures on the following line)
    measures = Dir.entries(File.expand_path("../measures/", __FILE__)).select {|entry| File.directory? File.join(File.expand_path("../measures/", __FILE__), entry) and !(entry == '.' || entry == '..') }
    measures.each do |m|
        testrbs = Dir[File.expand_path("../measures/#{m}/tests/*.rb", __FILE__)]
        if testrbs.size == 1
            # Get osm's specified in the test rb
            testrb = testrbs[0]
            osms = get_osms_listed_in_test(testrb)
            osms.each do |osm|
                osw = File.basename(osm).gsub('.osm','.osw')
                if not osw_map.keys.include?(osw)
                    osw_map[osw] = []
                end
                osw_map[osw] << m
            end
        elsif testrbs.size > 1
            puts "ERROR: Multiple .rb files found in #{m} tests dir."
            exit
      end
    end

    osw_files = Dir.entries(osw_path).select {|entry| entry.end_with?(".osw") and !osw_map[entry].nil?}
    if File.exists?(File.expand_path("../log", __FILE__))
        FileUtils.rm(File.expand_path("../log", __FILE__))
    end

    osw_files.each do |osw|

        # Generate osm from osw
        osw_filename = osw
        num_tot += 1
        
        puts "[#{num_tot}/#{osw_map.size}] Regenerating osm from #{osw}..."
        osw = File.expand_path("../test/osw_files/#{osw}", __FILE__)
        osm = File.expand_path("../test/osw_files/run/in.osm", __FILE__)
        command = "\"#{os_cli}\" run -w #{osw} -m >> log"
        for _retry in 1..3
            system(command)
            break if File.exists?(osm)
        end
        if not File.exists?(osm)
            puts "  ERROR: Could not generate osm."
            exit
        end

        # Add auto-generated message to top of file
        # Update EPW file paths to be relative for the CirceCI machine
        file_text = File.readlines(osm)
        File.open(osm, "w") do |f|
            f.write("!- NOTE: Auto-generated from #{osw.gsub(File.dirname(__FILE__), "")}\n")
            file_text.each do |file_line|
                if file_line.strip.start_with?("file:///")
                    file_data = file_line.split('/')
                    file_line = file_data[0] + "../tests/" + file_data[-1]
                end
                f.write(file_line)
            end
        end

        # Copy to appropriate measure test dirs
        osm_filename = osw_filename.gsub(".osw", ".osm")
        num_copied = 0
        osw_map[osw_filename].each do |measure|
            measure_test_dir = File.expand_path("../measures/#{measure}/tests/", __FILE__)
            if not Dir.exists?(measure_test_dir)
                puts "  ERROR: Could not copy osm to #{measure_test_dir}."
                exit
            end
            FileUtils.cp(osm, File.expand_path("#{measure_test_dir}/#{osm_filename}", __FILE__))
            num_copied += 1
        end
        puts "  Copied to #{num_copied} measure(s)."
        num_success += 1

        # Clean up
        run_dir = File.expand_path("../test/osw_files/run", __FILE__)
        if Dir.exists?(run_dir)
            FileUtils.rmtree(run_dir)
        end
        if File.exists?(File.expand_path("../test/osw_files/out.osw", __FILE__))
            FileUtils.rm(File.expand_path("../test/osw_files/out.osw", __FILE__))
        end
    end
    
    # Remove any extra osm's in the measures test dirs
    measures.each do |m|
        osms = Dir[File.expand_path("../measures/#{m}/tests/*.osm", __FILE__)]
        osms.each do |osm|
            osw = File.basename(osm).gsub('.osm','.osw')
            if not osw_map[osw].nil? and not osw_map[osw].include?(m)
                puts "Extra file #{osw} found in #{m}/tests. Do you want to delete it? (y/n)"
                input = STDIN.gets.strip.downcase
                next if input != "y"
                FileUtils.rm(osm)
                puts "File deleted."
            end
        end
    end    
    
    puts "Completed. #{num_success} of #{num_tot} osm files were regenerated successfully."
    
  end

end

desc 'update all measures (resources, xmls, workflows, README)'
task :update_measures do

  puts "Updating measure resources..."
  measures_dir = File.expand_path("../measures/", __FILE__)
  
  measures = Dir.entries(measures_dir).select {|entry| File.directory? File.join(File.expand_path("../measures/", __FILE__), entry) and !(entry == '.' || entry == '..') }
  measures.each do |m|
    measurerb = File.expand_path("../measures/#{m}/measure.rb", __FILE__)
    
    # Get recursive list of resources required based on looking for 'require FOO' in rb files
    resources = get_requires_from_file(measurerb)

    # Add any additional resources specified in resource_to_measure_mapping.csv
    subdir_resources = {} # Handle resources in subdirs
    File.open(File.expand_path("../resources/resource_to_measure_mapping.csv", __FILE__)) do |file|
      file.each do |line|
        line = line.chomp.split(',').reject { |l| l.empty? }
        measure = line.delete_at(0)
        next if measure != m
        line.each do |resource|
          fullresource = File.expand_path("../resources/#{resource}", __FILE__)
          next if resources.include?(fullresource)
          resources << fullresource
          if resource != File.basename(resource)
            subdir_resources[File.basename(resource)] = resource
          end
        end
      end
    end
    
    # Add/update resource files as needed
    resources.each do |resource|
      if not File.exist?(resource)
        puts "Cannot find resource: #{resource}."
        next
      end
      r = File.basename(resource)
      dest_resource = File.expand_path("../measures/#{m}/resources/#{r}", __FILE__)
      measure_resource_dir = File.dirname(dest_resource)
      if not File.directory?(measure_resource_dir)
        FileUtils.mkdir_p(measure_resource_dir)
      end
      if not File.file?(dest_resource)
        FileUtils.cp(resource, measure_resource_dir)
        puts "Added #{r} to #{m}/resources."
      elsif not FileUtils.compare_file(resource, dest_resource)
        FileUtils.cp(resource, measure_resource_dir)
        puts "Updated #{r} in #{m}/resources."
      end
    end
    
    # Any extra resource files?
    if File.directory?(File.expand_path("../measures/#{m}/resources", __FILE__))
      Dir.foreach(File.expand_path("../measures/#{m}/resources", __FILE__)) do |item|
        next if item == '.' or item == '..'
        if subdir_resources.include?(item)
          item = subdir_resources[item]
        end
        resource = File.expand_path("../resources/#{item}", __FILE__)
        next if resources.include?(resource)
        item_path = File.expand_path("../measures/#{m}/resources/#{item}", __FILE__)
        if File.directory?(item_path)
            puts "Extra dir #{item} found in #{m}/resources. Do you want to delete it? (y/n)"
            input = STDIN.gets.strip.downcase
            next if input != "y"
            puts "deleting #{item_path}"
            FileUtils.rm_rf(item_path)
            puts "Dir deleted."
        else
            puts "Extra file #{item} found in #{m}/resources. Do you want to delete it? (y/n)"
            input = STDIN.gets.strip.downcase
            next if input != "y"
            FileUtils.rm(item_path)
            puts "File deleted."
        end
      end
    end
    
  end
  
  # Update measure xmls
  command = "\"#{os_cli}\" measure --update_all #{measures_dir} >> log"
  puts "Updating measure.xml files..."
  system(command)
  
  # Generate example OSW
  generate_example_osw_of_all_measures_in_order

end

desc 'Copy resources from OpenStudio-ResStock repo'
task :copy_resstock_resources do  
  extra_files = [
                 File.join("resources", "helper_methods.rb")
                ]  
  extra_files.each do |extra_file|
      puts "Copying #{extra_file}..."
      resstock_file = File.join(File.dirname(__FILE__), "..", "OpenStudio-ResStock", extra_file)
      hpxml_file = File.join(File.dirname(__FILE__), extra_file)
      if File.exists?(hpxml_file)
        FileUtils.rm(hpxml_file)
      end
      FileUtils.cp(resstock_file, hpxml_file)
  end  
end

# This function will generate an OpenStudio OSW
# with all the measures in it, in the order specified in /resources/measure-info.json
#
#@return [Bool] true if successful, false if not
def generate_example_osw_of_all_measures_in_order()

  require 'openstudio'
  require_relative 'resources/helper_methods'

  puts "Updating example OSW..."
  
  model = OpenStudio::Model::Model.new
  osw_path = "workflows/create-model-example.osw"
  
  if File.exist?(osw_path)
    File.delete(osw_path)
  end
  
  workflowJSON = OpenStudio::WorkflowJSON.new
  workflowJSON.setOswPath(osw_path)
  workflowJSON.addMeasurePath("../measures")
  workflowJSON.setSeedFile("../seeds/EmptySeedModel.osm")
  
  # Check that there is no missing/extra measures in the measure-info.json
  # and get all_measures name (folders) in the correct order
  data_hash = get_and_proof_measure_order_json()
  
  steps = OpenStudio::WorkflowStepVector.new
  
  data_hash.each do |group|
    group["group_steps"].each do |group_step|
      
        measure = group_step["measures"][0]
        measure_path = File.expand_path(File.join("../measures", measure), workflowJSON.oswDir.to_s) 

        measure_instance = get_measure_instance("#{measure_path}/measure.rb")
        measure_args = measure_instance.arguments(model).sort_by {|arg| arg.name}
        
        step = OpenStudio::MeasureStep.new(measure)
        step.setName(measure_instance.name)
        step.setDescription(measure_instance.description)
        
        step.setModelerDescription(measure_instance.modeler_description)

        # Loop on each argument
        measure_args.each do |arg|
            if arg.hasDefaultValue
                step.setArgument(arg.name, arg.defaultValueAsString)
            elsif arg.required
                puts "Error: No default value provied for #{measure} argument '#{arg.name}'."
                exit
            end
        end
      
        # Push step in Steps
        steps.push(step)
    end 
  end

  workflowJSON.setWorkflowSteps(steps)
  workflowJSON.save
  
  # Copy osw into HPXMLBuildModel/resources
  json_path = "workflows/measure-info.json"
  dest_resource = File.expand_path("measures/HPXMLBuildModel/resources/#{File.basename(json_path)}")
  measure_resource_dir = File.dirname(dest_resource)  
  if not File.file?(dest_resource)
    FileUtils.cp(json_path, measure_resource_dir)
    puts "Added #{File.basename(json_path)} to HPXMLBuildModel/resources."
  elsif not FileUtils.compare_file(json_path, dest_resource)
    FileUtils.cp(json_path, measure_resource_dir)
    puts "Updated #{File.basename(json_path)} in HPXMLBuildModel/resources."
  end
  
  # Replace "\n" strings with newlines in the JSON
 # s = IO.read(osw_path)
 # s.gsub!("\\n", "\n")
 # File.write(osw_path, s)
  
  # Update README.md as well
  update_readme(data_hash)
  
end

# This method updates the "Measure Order" table in the README.md
def update_readme(data_hash)
  
  puts "Updating README measure order..."
  
  table_flag_start = "MEASURE_WORKFLOW_START"
  table_flag_end = "MEASURE_WORKFLOW_END"
  
  readme_path = "README.md"
  
  # Create table
  table_lines = []
  table_lines << "|Group|Measure|Dependencies*|\n"
  table_lines << "|:---|:---|:---|\n"
  data_hash.each do |group|
    new_group = true
    group["group_steps"].each do |group_step|
      grp = ""
      if new_group
        grp = group["group_name"]
      end
      name = group_step['name']
      deps = group_step['dependencies']
      table_lines << "|#{grp}|#{name}|#{deps}|\n"
      new_group = false
    end
  end
  
  # Embed table in README text
  in_lines = IO.readlines(readme_path)
  out_lines = []
  inside_table = false
  in_lines.each do |in_line|
    if in_line.include? table_flag_start
      inside_table = true
      out_lines << in_line
      out_lines << table_lines
    elsif in_line.include? table_flag_end
      inside_table = false
      out_lines << in_line
    elsif not inside_table
      out_lines << in_line
    end
  end
  
  File.write(readme_path, out_lines.join(""))
  
end

# This function will check that all measure folders (in measures/) 
# are listed in the /resources/measure-info.json and vice versa
# and return the list of all measures used in the proper order
#
# @return {data_hash} of measure-info.json
def get_and_proof_measure_order_json()
  # List all measures in measures/ folder
  beopt_measure_folder = File.expand_path("../measures/", __FILE__)
  all_measures = Dir.entries(beopt_measure_folder).select{|entry| entry.start_with?('Residential')}
  
  # Load json, and get all measures in there
  json_file = "workflows/measure-info.json"
  json_path = File.expand_path("../#{json_file}", __FILE__)
  data_hash = JSON.parse(File.read(json_path))

  measures_json = []
  data_hash.each do |group|
    group["group_steps"].each do |group_step|
      measures_json += group_step["measures"]
    end 
  end
  
  # Check for missing in JSON file
  missing_in_json = all_measures - measures_json
  if missing_in_json.size > 0
    puts "Warning: There are #{missing_in_json.size} measures missing in '#{json_file}': #{missing_in_json.join(",")}"
  end

  # Check for measures in JSON that don't have a corresponding folder
  extra_in_json = measures_json - all_measures
  if extra_in_json.size > 0
    puts "Warning: There are #{extra_in_json.size} measures extra in '#{json_file}': #{extra_in_json.join(",")}"
  end
  
  return data_hash
end

def get_requires_from_file(filerb)
  requires = []
  if not File.exists?(filerb)
    return requires
  end
  File.open(filerb) do |file|
    file.each do |line|
      line.strip!
      next if line.nil?
      next if not (line.start_with?("require \"\#{File.dirname(__FILE__)}/") or line.start_with?("require\"\#{File.dirname(__FILE__)}/"))
      line.chomp!("\"")
      d = line.split("/")
      requirerb = File.expand_path("../resources/#{d[-1].to_s}.rb", __FILE__)
      requires << requirerb
    end   
  end
  # Recursively look for additional requirements
  requires.each do |requirerb|
    get_requires_from_file(requirerb).each do |rb|
      next if requires.include?(rb)
      requires << rb
    end
  end
  return requires
end

def get_osms_listed_in_test(testrb)
    osms = []
    if not File.exists?(testrb)
      return osms
    end
    str = File.readlines(testrb).join("\n")
    osms = str.scan(/\w+\.osm/)
    return osms.uniq
end

def replace_name_in_measure_xmls()
    # This method replaces the <name> element in measure.xml
    # with the <display_name> value and returns the original
    # <name> values in a hash.
    # This is temporary code since the BCL currently looks
    # at the <name> element, rather than the <display_name>
    # element, in the measure.xml file. The BCL will be fixed
    # at some future point.
    name_hash = {}
    require 'rexml/document'
    require 'rexml/xpath'
    Dir.glob('./measures/*').each do |dir|
      next if dir.include?('Rakefile')
      measure_xml = File.absolute_path(File.join(dir, "measure.xml"))
      xmldoc = REXML::Document.new(File.read(measure_xml))
      orig_name = REXML::XPath.first(xmldoc, "//measure/name").text
      display_name = REXML::XPath.first(xmldoc, "//measure/display_name").text
      REXML::XPath.each(xmldoc, "//measure/name") do |node|
        node.text = display_name
      end
      xmldoc.write(File.open(measure_xml, "w"))
      name_hash[measure_xml] = orig_name
    end
    return name_hash
end

def revert_name_in_measure_xmls(name_hash)
    # This method reverts the <name> element in measure.xml
    # to its original value.
    require 'rexml/document'
    require 'rexml/xpath'
    Dir.glob('./measures/*').each do |dir|
      next if dir.include?('Rakefile')
      measure_xml = File.absolute_path(File.join(dir, "measure.xml"))
      xmldoc = REXML::Document.new(File.read(measure_xml))
      REXML::XPath.each(xmldoc, "//measure/name") do |node|
        node.text = name_hash[measure_xml]
      end
      xmldoc.write(File.open(measure_xml, "w"))
    end
end