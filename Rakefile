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
  
    # Generate hash that maps osw's to measures
    osw_map = {}
    missing_measure_dirs = []
    File.open(File.expand_path("../test/osw_to_measure_mapping.csv", __FILE__)) do |file|
      file.each do |line|
        line = line.chomp.split(',').reject { |l| l.empty? }
        measure = line.delete_at(0)
        line.each do |osw|
          osw_full = File.expand_path("../test/osw_files/#{osw}", __FILE__)
          if not File.exists?(osw_full)
            puts "ERROR: OSW file #{osw_full} not found."
          end
          measure_dir = File.expand_path("../measures/#{measure}/", __FILE__)
          if not Dir.exists?(measure_dir)
            if not missing_measure_dirs.include?(measure_dir)
              puts "ERROR: Measure dir #{measure_dir} not found."
              missing_measure_dirs << measure_dir
            end
          else
            if not osw_map.keys.include?(osw)
              osw_map[osw] = []
            end
            osw_map[osw] << measure
          end
        end
      end
    end

    os_cli = "C:\\openstudio-2.0.0\\bin\\openstudio.exe" # FIXME    
    os_version = os_cli.split('\\')[-3].split('-')[1]
    osw_files = Dir.entries(File.expand_path("../test/osw_files/", __FILE__)).select {|entry| entry.end_with?(".osw")}
    if File.exists?(File.expand_path("../log", __FILE__))
        FileUtils.rm(File.expand_path("../log", __FILE__))
    end
    osw_files.each do |osw|
        # Generate osm from osw
        osw_filename = osw
        next if osw_map[osw_filename].nil? # No measures to copy osm to
        num_tot += 1
        puts "Regenerating osm from #{osw}..."
        temp_osw = File.join(File.dirname(__FILE__), osw)
        osw = File.expand_path("../test/osw_files/#{osw}", __FILE__)
        FileUtils.cp(osw, temp_osw)
        command = "\"#{os_cli}\" run -w #{temp_osw} -m >> log"
        system(command)
        osm = File.expand_path("../run/in.osm", __FILE__)
        if not File.exists?(osm)
            puts "  ERROR: Could not generate osm."
        else
            # Add auto-generated message to top of file
            # Update EPW file paths to be relative for the CirceCI machine
            # FIXME: Temporarily replace OS 2.0 version with 1.14 for CircleCI machine
            file_text = File.readlines(osm)
            File.open(osm, "w") do |f|
                f.write("!- NOTE: Auto-generated from #{osw.gsub(File.dirname(__FILE__), "")}\n")
                file_text.each do |file_line|
                    if file_line.strip.start_with?("file:///")
                        file_data = file_line.split('/')
                        file_line = file_data[0] + "../tests/" + file_data[-1]
                    elsif file_line.include?("Version Identifier")
                        file_line = file_line.gsub(os_version, '1.14.0')
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
                end
                FileUtils.cp(osm, File.expand_path("#{measure_test_dir}/#{osm_filename}", __FILE__))
                num_copied += 1
            end
            puts "  Copied to #{num_copied} measure(s)."
            num_success += 1
        end
        # Clean up
        run_dir = File.expand_path("../run", __FILE__)
        if Dir.exists?(run_dir)
            FileUtils.rmtree(run_dir)
        end
        if File.exists?(temp_osw)
            FileUtils.rm(temp_osw)
        end
        if File.exists?(File.expand_path("../out.osw", __FILE__))
            FileUtils.rm(File.expand_path("../out.osw", __FILE__))
        end
    end
    
    puts "Completed. #{num_success} of #{num_tot} osm files were regenerated successfully."
    
  end

end

desc 'update all resources'
task :update_resources do

  require 'bcl'
  require 'openstudio'

  measures = Dir.entries(File.expand_path("../measures/", __FILE__)).select {|entry| File.directory? File.join(File.expand_path("../measures/", __FILE__), entry) and !(entry =='.' || entry == '..') }
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
        puts "Extra file #{item} found in #{m}/resources. Do you want to delete it? (y/n)"
        input = STDIN.gets.strip.downcase
        next if input != "y"
        FileUtils.rm(File.expand_path("../measures/#{m}/resources/#{item}", __FILE__))
        puts "File deleted."
      end
    end
    
    # Update measure xml
    measure_dir = File.expand_path("../measures/#{m}/", __FILE__)
    measure = OpenStudio::BCLMeasure.load(measure_dir)
    if not measure.empty?
        begin
            measure = measure.get

            file_updates = measure.checkForUpdatesFiles # checks if any files have been updated
            xml_updates = measure.checkForUpdatesXML # only checks if xml as loaded has been changed since last save
      
            if file_updates || xml_updates

                # try to load the ruby measure
                info = OpenStudio::Ruleset.getInfo(measure, OpenStudio::Model::OptionalModel.new, OpenStudio::OptionalWorkspace.new)
                info.update(measure)

                measure.save
            end
            
            
        rescue Exception => e
            puts e.message
        end
    end
    
    
  end

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