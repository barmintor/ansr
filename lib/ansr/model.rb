module Ansr
  module Model
    extend ActiveSupport::Concern
    module ClassMethods
      def spawn
        s = build_default_scope
        s.references!(references())
      end

      def inherited(subclass)
        super
        # a hack for sanitize sql overrides to work, and some others where @klass used in place of klass()
        subclass.instance_variable_set("@klass", subclass)
        # a hack for the intermediate abstract model classes to work with table_name
        subclass.instance_variable_set("@table_name", subclass.name)
      end

      def model
        m = begin
          instance_variable_get "@klass"
        end
        raise "#{name()}.model() -> nil" unless m
        m
      end

      def references
        []
      end

      def table
        type = (config[:table_class] || Ansr::Arel::BigTable)
        if @table
          # allow the table class to be reconfigured
          @table = nil unless @table.class == type
        end
        @table ||= type.new(self)
      end

      def engine
        model()
      end

      def model
        @klass
      end

      def build_default_scope
        Ansr::Relation.new(model(), table())
      end

      def column_types
        TypeProxy.new(table())
      end

      class TypeProxy
        def initialize(table)
          @table = table
        end

        def [](name)
          # this should delegate to the NoSqlAdapter
          ::ActiveRecord::ConnectionAdapters::Column.new(name.to_s, nil, String)
        end
      end
    end

    require 'ansr/model/connection_handler'
  end
end