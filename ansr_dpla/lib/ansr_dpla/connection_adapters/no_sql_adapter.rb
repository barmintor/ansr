module Ansr::Dpla
  module ConnectionAdapters
    class NoSqlAdapter < Ansr::ConnectionAdapters::NoSqlAdapter

      def self.connection_for(klass)
        klass.api
      end

      def initialize(klass, logger = nil, pool = nil) #:nodoc:
        super(klass, klass.api, logger, pool)
        @visitor = Ansr::Dpla::Arel::Visitors::ToNoSql.new(@table)
      end

      def to_sql(*args)
        to_nosql(*args)
      end

      def execute(query, name='ANSR-DPLA')
        method = query.path
        query = query.to_h if Ansr::Dpla::Request === query
        query = query.dup
        aliases = query.delete(:aliases)
        json = @connection.send(method, query)
        json = json.length > 0 ? JSON.load(json) : {'docs' => [], 'facets' => []}
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

      def table_exists?(table_name)
        ['Collection', 'Item'].include? table_name
      end

      def sanitize_limit(limit_value)
        if (0..500) === limit_value.to_s.to_i
          limit_value
        else
          Ansr::Relation::DEFAULT_PAGE_SIZE
        end
      end

    end
  end
 
end