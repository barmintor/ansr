module Ansr
  module Arel
    autoload :ConfiguredField, 'ansr/arel/configured_field'
    require 'ansr/arel/big_table'
    require 'ansr/arel/nodes'
    require 'ansr/arel/visitors'
  end
end