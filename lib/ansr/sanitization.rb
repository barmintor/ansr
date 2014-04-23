module Ansr
	module Sanitization
    extend ActiveSupport::Concern
    module ClassMethods
      def expand_hash_conditions_for_sql_aggregates(conditions)
        conditions
      end

      def sanitize_sql_for_conditions(condition, table_name = table_name())
        condition
      end

      def sanitize_sql_hash_for_conditions(attrs, default_table_name = self.table_name)
        attrs
      end

      def sanitize_sql(condition, table_name = table_name())
        sanitize_sql_for_conditions(condition, table_name)
      end
    end
  end
end