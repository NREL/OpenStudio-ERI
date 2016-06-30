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
  add_filter '/measures/.*/resources/'
  add_filter '/measures/.*/tests/'
end

require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress
