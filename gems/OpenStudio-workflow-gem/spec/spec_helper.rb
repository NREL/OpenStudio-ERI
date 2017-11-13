require 'simplecov'
require 'coveralls'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'spec/files'
end

developer_os_version = 0

if developer_os_version.zero?
  # use system libs
elsif developer_os_version == 1
  # for testing with OpenStudio 1.X
  #os_dir = 'E:/openstudio-1-14/build/OSCore-prefix/src/OSCore-build/ruby/Debug'
  os_dir = 'C:/Program Files/OpenStudio 1.14.0/Ruby'
  $LOAD_PATH.reject! { |p| /site_ruby$/.match(p) }
  $LOAD_PATH.unshift(os_dir)
elsif developer_os_version == 2
  # for testing with OpenStudio 2.X
  os_dir = 'E:/openstudio/build/Products/ruby/Debug'
  #os_dir = 'E:/openstudio2/build/Products/ruby/Debug'
  #os_dir = 'C:/openstudio-2.1.1/Ruby'
  #os_dir = 'C:/openstudio-2.1.2/Ruby'
  $LOAD_PATH.reject! { |p| /site_ruby$/.match(p) }
  old_dir = Dir.pwd
  Dir.chdir(os_dir)
  $LOAD_PATH.unshift(os_dir)
  require('openstudio')
  Dir.chdir(old_dir)
end

# for all testing
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'openstudio-workflow'
require 'json'

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end
