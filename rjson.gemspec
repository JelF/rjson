# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rjson/version'

Gem::Specification.new do |spec|
  spec.name          = 'rjson'
  spec.version       = RJSON::VERSION
  spec.authors       = ['Alexander Smirnov']
  spec.email         = ['begdory4@gmail.com']

  spec.summary       = <<-TXT.strip
    RJSON describes RJSON (Ruby JSON) serializer and RJSON format.
  TXT

  spec.homepage      = 'https://github.com/JelF/rjson'
  spec.require_paths = ['lib']

  spec.files =
    `git ls-files -z`
    .split("\x0")
    .reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.required_ruby_version = '~> 2.2'
  spec.platform = 'ruby'

  spec.add_dependency 'memoist'
  spec.add_dependency 'activesupport'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.38.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'launchy'
end
