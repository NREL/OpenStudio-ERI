require 'bundler'
Bundler.setup

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

require 'pp'
require 'colored'
require 'json'

namespace :test do

  desc 'Run unit tests for all measures'
  Rake::TestTask.new('measures') do |t|
    t.libs << 'test'
    t.test_files = Dir['measures/*/tests/*.rb']
    t.warning = false
    t.verbose = true
  end
  
  desc 'Run simulation tests for all sample files'
  Rake::TestTask.new('simulations') do |t|
    t.libs << 'test'
    t.test_files = Dir['workflow/tests/*.rb']
    t.warning = false
    t.verbose = true
  end
  
  desc 'Run all tests'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['measures/*/tests/*.rb'] + Dir['workflow/tests/*.rb']
    t.warning = false
    t.verbose = true
  end
  
end
  
desc 'generate sample outputs'
task :generate_sample_outputs do
  require 'openstudio'
  Dir.chdir('workflow')
  
  FileUtils.rm_rf("sample_results/.", secure: true)
  sleep 1
  FileUtils.mkdir_p("sample_results")

  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" execute_ruby_script energy_rating_index.rb -x sample_files/valid.xml"
  system(command)
  
  dirs = ["HERSRatedHome", "HERSReferenceHome", "results"]
  dirs.each do |dir|
    FileUtils.copy_entry dir, "sample_results/#{dir}"
  end
end
