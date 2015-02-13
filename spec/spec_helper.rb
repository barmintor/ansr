$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
ENV["RAILS_ENV"] ||= 'test'
require 'ansr'
require 'rails/all'
require 'rspec/rails'
require 'kaminari'
require 'loggable'
