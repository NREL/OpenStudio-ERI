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

  all_tests = Dir['measures/*/tests/*.rb']
  group_size = (all_tests.size/4.0).ceil

  # Split into equal groups for CircleCI parallelization
  measures_group_0 = FileList[all_tests.each_slice(group_size).to_a[0]]
  
  measures_group_1 = FileList[all_tests.each_slice(group_size).to_a[1]]

  measures_group_2 = FileList[all_tests.each_slice(group_size).to_a[2]]
                              
  measures_group_3 = FileList[all_tests.each_slice(group_size).to_a[3]]
                              
  desc 'Run unit tests for all measures in group 0'
  Rake::TestTask.new('measures_group_0') do |t|
    t.libs << 'test'
    t.test_files = measures_group_0
    t.warning = false
    t.verbose = true
  end

  desc 'Run unit tests for all measures in group 1'
  Rake::TestTask.new('measures_group_1') do |t|
    t.libs << 'test'
    t.test_files = measures_group_1
    t.warning = false
    t.verbose = true
  end

  desc 'Run unit tests for all measures in group 2'
  Rake::TestTask.new('measures_group_2') do |t|
    t.libs << 'test'
    t.test_files = measures_group_2
    t.warning = false
    t.verbose = true
  end

  desc 'Run unit tests for all measures in group 3'
  Rake::TestTask.new('measures_group_3') do |t|
    t.libs << 'test'
    t.test_files = measures_group_3
    t.warning = false
    t.verbose = true
  end

  desc 'Run unit tests for all measures'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = all_tests
    t.warning = false
    t.verbose = true
  end
end

task default: 'test:all'

desc 'update all resources'
task :update_resources do

  require 'bcl'
  require 'openstudio'

  measures = Dir.entries(File.expand_path("../measures/", __FILE__)).select {|entry| File.directory? File.join(File.expand_path("../measures/", __FILE__), entry) and !(entry =='.' || entry == '..') }
  measures.each do |m|
    measurerb = File.expand_path("../measures/#{m}/measure.rb", __FILE__)
    
    # Get recursive list of resources required based on looking for 'require FOO' in rb files
    resources = get_requires_from_file(measurerb)

    # Add any additional resources specified in resources.csv
    subdir_resources = {} # Handle resources in subdirs
    File.open(File.expand_path("../resources/resources.csv", __FILE__)) do |file|
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