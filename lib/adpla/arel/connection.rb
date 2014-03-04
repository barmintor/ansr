module Adpla
  module Arel
    class Connection
      def initialize(table)
        @table = table
        @method = table.name.downcase.pluralize.to_sym
        @api = table.engine.api
      end

      def to_sql(*args)
        to_nosql(*args)
      end

      def to_nosql(select_manager, bind_values)
        qb = Adpla::Arel::QueryBuilder.new(@table)
        select_manager.constraints.each {|c| qb.where(c)}
        select_manager.orders.each {|c| qb.order(c)}
        select_manager.projections.each {|c| qb.select(c)}
        qb.take(select_manager.limit) if select_manager.limit
        qb.skip(select_manager.offset) if select_manager.offset
        qb.query_opts
      end

      def to_aliases(select_manager, bind_values)
        qb = Adpla::Arel::QueryBuilder.new(@table)
        select_manager.projections.each {|c| qb.select(c)}
        qb.aliases
      end

      def execute(query, aliases = {})
        json = @api.send(@method, query)
        json = json.length > 0 ? JSON.load(json) : {}
        if json['docs'] and aliases
          json['docs'].each do |doc|
            aliases.each do |k,v|
              if doc[k]
                old = doc.delete(k)
                if old and doc[v]
                  doc[v] = Array(doc[v]) if doc[v]
                  Array(old).each {|ov| doc[v] << ov}
                else
                  doc[v] = old
                end
              end
            end
          end
        end
        json
      end

      def connected?
        true
      end

      def sanitize_limit(limit_value)
        if limit_value.to_s.to_i > -1
          limit_value
        else
          ActiveNoSql::Relation::DEFAULT_PAGE_SIZE
        end
      end

      def sanitize_filter_name(filter_value)
        if filter_value.is_a? Array
          return filter_value.collect {|x| sanitize_filter_name(x)}.compact
        else
          if BigTable::FACETS.include? filter_value.to_sym
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