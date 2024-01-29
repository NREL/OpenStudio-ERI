# frozen_string_literal: true

# This file is only used to run all tests and collect results on the CI.
# All rake tasks have been moved to tasks.rb.

require 'rake'
require 'rake/testtask'

desc 'Run all tests'
Rake::TestTask.new('test_all') do |t|
  t.test_files = Dir['rulesets/tests/*.rb'] + Dir['workflow/tests/*.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run ruleset tests'
Rake::TestTask.new('test_rulesets') do |t|
  t.test_files = Dir['rulesets/tests/*.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run Sample Files 1 tests'
Rake::TestTask.new('test_sample_files1') do |t|
  t.test_files = Dir['workflow/tests/sample_files1_test.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run Sample Files 2 tests'
Rake::TestTask.new('test_sample_files2') do |t|
  t.test_files = Dir['workflow/tests/sample_files2_test.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run Real Home tests'
Rake::TestTask.new('test_real_homes') do |t|
  t.test_files = Dir['workflow/tests/real_homes_test.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run Other tests'
Rake::TestTask.new('test_other') do |t|
  t.test_files = Dir['workflow/tests/*test.rb'] - Dir['workflow/tests/real_homes_test.rb'] - Dir['workflow/tests/sample_files*test.rb']
  t.warning = false
  t.verbose = true
end
