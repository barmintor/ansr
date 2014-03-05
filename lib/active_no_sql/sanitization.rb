module ActiveNoSql
	module Sanitization
    extend ActiveSupport::Concern
    module ClassMethods
      def reflect_on_association(column_sym)
        DummyReflection.new(column_sym)
      end

      def expand_hash_conditions_for_sql_aggregates(conditions)
        conditions
      end

      def sanitize_sql_for_conditions(condition, table_name = table_name())
        condition
      end

      def sanitize_sql(condition, table_name = table_name())
        sanitize_sql_for_conditions(condition, table_name)
      end

    end
    class DummyReflection
      def initialize(symbol)
        @symbol = symbol
      end

      def polymorphic?
        false
      end

      def foreign_key
        @symbol
      end
    end
  end
end