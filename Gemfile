source 'http://rubygems.org'

gem 'rake', '~> 11.2.2'

# uncomment if you need to update the bcl measures
# gem "bcl", "~> 0.5"
# gem "bcl", :path => "../bcl-gem"
gem 'bcl', git: 'https://github.com/NREL/bcl-gem', branch: 'develop'

# Specify the JSON dependency so that rubocop and other gem do not try to install it
gem 'json', '~> 1.7.7'

gem 'colored', '~> 1.2'

if RUBY_PLATFORM =~ /win32/
  gem 'win32console', '~> 1.3.2', platform: [:mswin, :mingw]
end

group :test do
  gem 'minitest', '~> 5.4.0'
  gem 'rubocop', '~> 0.26.0'
  gem 'rubocop-checkstyle_formatter', '~> 0.1.1'
  gem 'ci_reporter_minitest', '~> 1.0.0'
  gem 'coveralls'
  gem 'minitest-reporters'
  gem 'minitest-ci', :git => 'https://github.com/circleci/minitest-ci.git' # For CircleCI Automatic test metadata collection
end

gem 'docker-api', require: 'docker'