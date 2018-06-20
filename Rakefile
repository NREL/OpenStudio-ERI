require 'bundler'
Bundler.setup

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

require 'pp'
require 'colored'
require 'json'

namespace :test do

  desc 'Run all tests'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['measures/*/tests/*.rb'] + Dir['workflow/tests/energy_rating_index_test.rb']
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
