require File.join(File.dirname(__FILE__), '../lib/ansr/version')
version = Ansr.version
Gem::Specification.new do |spec|
  spec.name = 'ansr_dpla'
  spec.version = version
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Benjamin Armintor"]
  spec.email = ["armintor@gmail.com"]
  spec.summary = 'ActiveRecord-style models and relations for DPLA APIs'
  spec.description = 'Wrapping the DPLA APIs in Rails-like models and relations'
  spec.homepage = 'https://github.com/barmintor/ansr/tree/master/ansr_dpla'
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'ansr', version
  spec.add_dependency 'json-ld'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'loggable'
  spec.add_dependency 'sass-rails'
  spec.add_development_dependency("rake")
  spec.add_development_dependency("bundler", ">= 1.0.14")
  spec.add_development_dependency "rspec/rails", ">=3"
  spec.add_development_dependency("yard")
end