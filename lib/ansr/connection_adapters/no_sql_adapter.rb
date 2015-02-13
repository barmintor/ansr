require 'active_record'
require 'arel/visitors/bind_visitor'
module Ansr
  module ConnectionAdapters
    class NoSqlAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
      attr_reader :table
      def initialize(klass, connection, logger = nil, pool = nil)
        super(connection, logger, pool)
        @table = klass.table
        @visitor = nil
      end

      # Converts an arel AST to NOSQL Query
      def to_nosql(arel, binds = [])
        arel = arel.ast if arel.respond_to?(:ast)
        if arel.is_a? ::Arel::Nodes::Node
          binds = binds.dup
          visitor.accept(arel) do
            quote(*binds.shift.reverse)
          end
        else # assume it is already serialized
          arel
        end
      end

      # attr_accessor :visitor is a self.class::BindSubstitution in unprepared contexts
      class BindSubstitution < ::Arel::Visitors::MySQL # :nodoc:
        include ::Arel::Visitors::BindVisitor
      end

      # Executes +query+ statement in the context of this connection using
      # +binds+ as the bind substitutes. +name+ is logged along with
      # the executed +query+ statement.
      def execute(query, name = 'ANSR-NOSQL')
      end

      # called back from ::Arel::Table
      def primary_key(table_name)
        'id' # table.primary_key || 'id'
      end

      def table_exists?(name)
        true
      end

      def schema_cache
        ActiveRecord::ConnectionAdapters::SchemaCache.new(self)
      end

      # this is called by the BigTable impl
      # should it be retired in favor of the more domain-appropriate 'fields'? Not usually seen by clients anyway.
      def columns(table_name, *rest)
        @table.fields.map {|s| ::ActiveRecord::ConnectionAdapters::Column.new(s.to_s, nil, String)}
      end

      def sanitize_limit(limit_value)
        if limit_value.to_s.to_i >= 0
          limit_value
        else
          Ansr::Relation::DEFAULT_PAGE_SIZE
        end
      end

      def sanitize_filter_name(filter_value)
        if filter_value.is_a? Array
          return filter_value.collect {|x| sanitize_filter_name(x)}.compact
        else
          if @table.facets.include? filter_value.to_sym
            return filter_value
          else
            raise "#{filter_value} is not a filterable field"
            #Rails.logger.warn "Ignoring #{filter_value} (not a filterable field)" if Rails.logger
            #return nil
          end
        end
      end

    end
  end
end