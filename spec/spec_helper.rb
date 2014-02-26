$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app/models'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec/autorun'
require 'loggable'
require 'adpla'
require 'adpla_test_api'
require 'blacklight'
require 'item'
require 'collection'

RSpec.configure do |config|

end

def fixture path, &block
  path = File.join(File.dirname(__FILE__), '..', 'fixtures', path)
	if block_given?
    open(path) &block
  else
    open(path)
  end
end

def read_fixture(path)
  _f = fixture(path)
  _f.read
ensure
  _f and _f.close
end
