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
  spec.license = "APACHE2"
  spec.required_ruby_version = '>= 1.9.3'
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'loggable'
  spec.add_dependency 'arel', '~> 4', '>= 4.0.2'
  spec.add_dependency "rails",     ">= 3.2.6", "< 5"
  spec.add_dependency "kaminari", "~> 0.13"  # the pagination (page 1,2,3, etc..) of our search results

  spec.add_development_dependency("rake")
  spec.add_development_dependency("bundler", ">= 1.0.14")
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency("yard")
end