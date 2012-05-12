# -*- encoding: utf-8 -*-
require File.expand_path('../lib/chemicals/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ["Mattias Putman"]
  s.email         = ["mattias.putman@gmail.com"]
  s.description   = %q{Clever XML Parsing library}
  s.summary       = %q{Clever XML Parsing library}
  s.homepage      = ""

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.name          = "chemicals"
  s.require_paths = ["lib"]
  s.version       = Chemicals::VERSION

  s.add_dependency 'nokogiri'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-minitest'
end
