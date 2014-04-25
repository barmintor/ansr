require File.join(File.dirname(__FILE__), '../lib/ansr/version')
version = Ansr.version
Gem::Specification.new do |spec|
  spec.name = 'ansr_blacklight'
  spec.version = version
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Benjamin Armintor"]
  spec.email = ["armintor@gmail.com"]
  spec.summary = 'ActiveRecord-style models and relations for Blacklight'
  spec.description = 'Wrapping the Blacklight/RSolr in Rails-like models and relations'
  spec.homepage = 'https://github.com/barmintor/ansr/tree/master/ansr_blacklight'
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'ansr', version
  spec.add_dependency 'json-ld'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'loggable'
  spec.add_dependency "rails",     ">= 3.2.6", "< 5"
  spec.add_dependency "rsolr",     "~> 1.0.6"  # Library for interacting with rSolr.
  spec.add_dependency "kaminari", "~> 0.13"  # the pagination (page 1,2,3, etc..) of our search results
  spec.add_dependency 'sass-rails'
  spec.add_development_dependency("rake")
  spec.add_development_dependency("bundler", ">= 1.0.14")
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency("yard")
end