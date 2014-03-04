require 'active_record'
module Adpla
  module Arel
    require 'adpla/arel/big_table'
    require 'adpla/arel/connection'
    require 'adpla/arel/engine'
    require 'adpla/arel/query_builder'

    class PredicateBuilder < ::ActiveRecord::PredicateBuilder

      def self.build_from_hash(klass, attributes)
        queries = []
        table = klass.table
        attributes.each do |field, value|
          if value.is_a?(Hash)
            if value.empty?
              queries << '1=0'
            else
              value.each do |k, v|
                queries.concat expand(false, table, k, v)
              end
            end
          else
            field = field.to_s

            queries.concat expand(klass, table, field, value)
          end
        end
        queries
      end
    end
  end
end