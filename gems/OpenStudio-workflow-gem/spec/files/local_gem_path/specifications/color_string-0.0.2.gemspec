# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'color_string'
  s.version = '0.0.2'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Sean Doyle']
  s.date = '2014-07-14'
  s.description = 'Color your shell strings'
  s.email = ['sean.p.doyle24@gmail.com']
  s.homepage = 'https://github.com/seanpdoyle/color_string'
  s.licenses = ['MIT']
  s.require_paths = ['lib']
  s.rubygems_version = '2.0.14.1'
  s.summary = 'Color your shell strings'

  if s.respond_to? :specification_version
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0')
      s.add_development_dependency('bundler', ['~> 1.6'])
      s.add_development_dependency('rake', ['>= 0'])
    else
      s.add_dependency('bundler', ['~> 1.6'])
      s.add_dependency('rake', ['>= 0'])
    end
  else
    s.add_dependency('bundler', ['~> 1.6'])
    s.add_dependency('rake', ['>= 0'])
  end
end
