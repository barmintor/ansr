$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app/models'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV["RAILS_ENV"] ||= 'test'
require 'ansr'
require 'rails/all'
require 'rspec/rails'
require 'rspec/collection_matchers'
require 'loggable'
require 'ansr_blacklight'

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
#  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #config.use_transactional_fixtures = true
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

def stub_solr(response='')
  solr = double('Solr')
  solr.stub(:send_and_receive).and_return(eval(response))
  solr
end

def create_response(response, params = {})
  Ansr::Blacklight::Solr::Response.new(response, params)
end

class TestModel < Ansr::Blacklight::Base
  configure do |config|
    config[:unique_key] = 'id'
  end
  def self.solr=(solr)
    @solr = solr
  end
  def self.solr
    @solr
  end
end
