require 'active_record'
module Adpla
  module Arel
    class AdplaQuery
      attr_reader :query_opts, :aliases, :table
      def initialize(big_table)
        @query_opts = {}
        @aliases = {}
        @table = big_table
      end
      def fields=(value)
        @query_opts[:fields] = value
      end

      def where(arel_nodes)
        arel_nodes.children.each do |node|
          case node
            when ::Arel::Nodes::Equality
              if @query_opts[node.left.name.to_sym]
                @query_opts[node.left.name.to_sym] = Array[@query_opts[node.left.name.to_sym]] << node.right
              else
                @query_opts[node.left.name.to_sym] = node.right
              end
            when ::Arel::Nodes::Grouping
              n = node.expr
              if ::Arel::Nodes::NotEqual === n
                val = "NOT #{n.right}"
                if @query_opts[n.left.name.to_sym]
                  @query_opts[n.left.name.to_sym] = Array[@query_opts[n.left.name.to_sym]] << val
                else
                  @query_opts[n.left.name.to_sym] = val
                end
              end
            else
              puts "GOT AN UNEXPECTED NODE #{node.inspect}"
          end
        end
      end

      def order(*arel_nodes)
        direction = nil
        nodes = []
        arel_nodes.inject(nodes) do |c, n|
          if ::Arel::Nodes::Ordering === n
            c << n
          elsif n.is_a? String
            _ns = n.split(',')
            _ns.each do |_n| 
              _p = _n.split(/\s+/)
              if (_p[1])
                _p[1] = _p[1].downcase.to_sym
              else
                _p[1] = :asc
              end
              c << table[_p[0].to_sym].send(_p[1])
            end
          end
          c
        end
        nodes.each do |node|
          if ::Arel::Nodes::Ordering === node
            if @query_opts[:sort_by]
              @query_opts[:sort_by] = Array[@query_opts[:sort_by]] << node.expr.name
            else
              @query_opts[:sort_by] = node.expr.name
            end
            direction = :asc if (::Arel::Nodes::Ascending === node and direction)
            direction = :desc if (::Arel::Nodes::Descending === node)
          end
        end
        @query_opts[:sort_order] = direction if direction
      end

      def take(value=nil)
        @query_opts[:page_size] = value.to_i if value
      end

      def skip(value=nil)
        if value
          @query_opts[:page] = (value.to_i / (@query_opts[:page_size] || Relation::DEFAULT_PAGE_SIZE)) + 1
        end
      end
    end

    class BigTable
      def initialize(opts={})
        @fields = (opts[:fields] || []).dup
        @facets = (opts[:facets] || []).dup
        @sorts = (opts[:sorts] || []).dup
      end

      def [](name)
        ::Arel::Attribute.new(self, name)
      end
    end

    class PredicateBuilder < ::ActiveRecord::PredicateBuilder
      def self.big_table
        @big_table ||= BigTable.new
      end

      def self.build_from_hash(klass, attributes)
        queries = []
        table = self.big_table
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