require 'simplecov'
require 'coveralls'

# Get the code coverage in html for local viewing
# and in JSON for coveralls
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

# Ignore some of the code in coverage testing
SimpleCov.start do
  add_filter '/geometries/'
  add_filter '/resources/'
  add_filter '/test/'
end

require 'minitest/reporters'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress
