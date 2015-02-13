$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app/models'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec/autorun'
require 'loggable'
require 'ansr'
require 'ansr_dpla'
require 'adpla_test_api'
require 'item'
require 'collection'

RSpec.configure do |config|

end

def fixture_path(path)
  File.join(File.dirname(__FILE__), '..', 'fixtures', path)
end

def fixture path, &block
  if block_given?
    open(fixture_path(path)) &block
  else
    open(fixture_path(path))
  end
end

def read_fixture(path)
  _f = fixture(path)
  _f.read
ensure
  _f and _f.close
end
