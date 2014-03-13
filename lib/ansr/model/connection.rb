module ActiveNoSql
	module Model
    class Connection
      def initialize(klass)
        @table = klass.table
      end

      def primary_key(table_name)
        'id'
      end

      def limit(arel_node)
        case arel_node
        when ::Arel::SelectManager
          arel_node.limit
        when ::Arel::Nodes::SelectStatement
          arel_node.limit && arel_node.limit.expr
        else
          nil
        end
      end

      def offset(arel_node)
        case arel_node
        when ::Arel::SelectManager
          arel_node.offset
        when ::Arel::Nodes::SelectStatement
          arel_node.offset && arel_node.offset.expr
        else
          nil
        end
      end

      def constraints(arel_node)
        case arel_node
        when ::Arel::SelectManager
          arel_node.constraints
        when ::Arel::Nodes::SelectStatement
          arel_node.cores.last.wheres
        else
          nil
        end
      end

      def projections(arel_node)
        case arel_node
        when ::Arel::SelectManager
          arel_node.projections
        when ::Arel::Nodes::SelectStatement
          arel_node.cores.last.projections
        else
          nil
        end
      end        

      def orders(arel_node)
        case arel_node
        when ::Arel::SelectManager
          arel_node.orders
        when ::Arel::Nodes::SelectStatement
          arel_node.orders
        else
          nil
        end
      end        

      def schema_cache
        ActiveRecord::ConnectionAdapters::SchemaCache.new(self)
      end

      def table_exists?(table_name)
        true
      end

      # this is called by the BigTable impl
      def columns(table_name, *rest)
        @table.fields.map {|s| ::ActiveRecord::ConnectionAdapters::Column.new(s.to_s, nil, nil)}
      end

      def sanitize_limit(limit_value)
        if limit_value.to_s.to_i >= 0
          limit_value
        else
          ActiveNoSql::Relation::DEFAULT_PAGE_SIZE
        end
      end

      def sanitize_filter_name(filter_value)
        if filter_value.is_a? Array
          return filter_value.collect {|x| sanitize_filter_name(x)}.compact
        else
          if @table.facets.include? filter_value.to_sym
            return filter_value
          else
            raise "#{filter_value} is not a facetable field"
            #Rails.logger.warn "Ignoring #{filter_value} (not a filterable field)" if Rails.logger
            #return nil
          end
        end
      end
    end
  end
end