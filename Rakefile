require 'bundler'
Bundler.setup

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

require 'pp'
require 'colored'
require 'json'

# Get latest installed version of openstudio.exe
os_clis = Dir["C:/openstudio-*/bin/openstudio.exe"] + Dir["/usr/bin/openstudio"] + Dir["/usr/local/bin/openstudio"]
if os_clis.size == 0
    puts "ERROR: Could not find the openstudio binary. You may need to install the OpenStudio Command Line Interface."
    exit
end
os_cli = os_clis[-1]

namespace :test do

  desc 'Run unit tests for all measures'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['measures/*/tests/*.rb'] + Dir['workflows/energy_rating_index/tests/*.rb']
    t.warning = false
    t.verbose = true
  end
  
end
  
desc 'Copy measures/osms from OpenStudio-BEopt repo'
task :copy_beopt_files do
  require 'fileutils'
  
  # TODO: Should really grab latest from https://github.com/NREL/OpenStudio-BEopt/archive/master.zip
  beopt_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "OpenStudio-BEopt"), __FILE__)

  beopt_measures_dir = File.join(beopt_dir, "measures")
  resource_measures_dir = File.join(File.dirname(__FILE__), "resources", "measures")
  if not Dir.exist?(beopt_measures_dir)
    puts "Cannot find OpenStudio-BEopt measures dir at #{beopt_measures_dir}."
  end
  
  # Clean out resources/measures/ dir
  puts "Deleting #{resource_measures_dir}..."
  while Dir.exist?(resource_measures_dir)
    FileUtils.rm_rf("#{resource_measures_dir}/.", secure: true)
    sleep 1
  end
  FileUtils.makedirs(resource_measures_dir)
  
  # Copy residential measures to resources/measures/
  Dir.foreach(beopt_measures_dir) do |beopt_measure|
    next if !beopt_measure.include? 'Residential'
    beopt_measure_dir = File.join(beopt_measures_dir, beopt_measure)
    next if not Dir.exist?(beopt_measure_dir)
    puts "Copying #{beopt_measure} measure..."
    FileUtils.cp_r(beopt_measure_dir, resource_measures_dir)
    ["coverage","tests"].each do |subdir|
      buildstock_resource_measures_subdir = File.join(resource_measures_dir, beopt_measure, subdir)
      if Dir.exist?(buildstock_resource_measures_subdir)
        FileUtils.rm_rf("#{buildstock_resource_measures_subdir}/.", secure: true)
      end
    end
  end

  # Copy resources/*.rb from BEopt
  beopt_resources_dir = File.join(beopt_dir, "resources")
  resources = Dir.entries(beopt_resources_dir).select {|entry| entry.end_with?('.rb') }
  resources.each do |resource|
    resource = File.expand_path(File.join(beopt_resources_dir, resource), __FILE__)
    dest_resource = resource.gsub(beopt_dir, File.dirname(__FILE__))
    if not FileUtils.compare_file(resource, dest_resource)
      FileUtils.cp(resource, dest_resource)
      puts "Copied #{File.basename(resource)} to resources."
    end
  end
  
  # Copy seed OSM
  seed_osm = File.join("seeds", "EmptySeedModel.osm")
  src_seed = File.join(beopt_dir, seed_osm)
  dest_seed = File.join(File.dirname(__FILE__), seed_osm)
  if not FileUtils.compare_file(src_seed, dest_seed)
    FileUtils.cp(src_seed, dest_seed)
    puts puts "Copied #{File.basename(seed_osm)} to #{File.dirname(seed_osm)}."
  end
  
end

desc 'update all measures (resources, xmls)'
task :update_measures do

  puts "Updating measure resources..."
  measures_dir = File.expand_path("../measures/", __FILE__)
  
  measures = Dir.entries(measures_dir).select {|entry| File.directory? File.join(File.expand_path("../measures/", __FILE__), entry) and !(entry == '.' || entry == '..') }
  measures.each do |m|
    measurerb = File.expand_path("../measures/#{m}/measure.rb", __FILE__)
    
    # Get recursive list of resources required based on looking for 'require FOO' in rb files
    resources = get_requires_from_file(measurerb)
    
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
            next if item == 'measure-info.json'
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
