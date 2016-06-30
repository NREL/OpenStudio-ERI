require 'simplecov'
require 'coveralls'

# Get the code coverage in html for local viewing
# and in JSON for coveralls
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

require 'minitest/reporters'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress
