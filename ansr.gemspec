require File.join(File.dirname(__FILE__), 'lib/ansr/version')
Gem::Specification.new do |spec|
  spec.name = 'ansr'
  spec.version = Ansr.version
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Benjamin Armintor"]
  spec.email = ["armintor@gmail.com"]
  spec.summary = 'ActiveRecord-style relations for no-sql data sources'
  spec.description = 'Wrapping the no-sql data sources in Rails-like models and relations'
  spec.homepage = 'http://github.com/barmintor/ansr'
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'loggable'
  spec.add_dependency 'arel'
  spec.add_dependency 'activerecord'
  spec.add_dependency 'blacklight', '>=5.1.0'

  spec.add_development_dependency("rake")
  spec.add_development_dependency("bundler", ">= 1.0.14")
  spec.add_development_dependency("rspec")
  spec.add_development_dependency("yard")
end