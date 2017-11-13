# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'color_string/version'

Gem::Specification.new do |spec|
  spec.name          = 'color_string'
  spec.version       = ColorString::VERSION
  spec.authors       = ['Sean Doyle']
  spec.email         = ['sean.p.doyle24@gmail.com']
  spec.summary       = 'Color your shell strings'
  spec.description   = 'Color your shell strings'
  spec.homepage      = 'https://github.com/seanpdoyle/color_string'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
