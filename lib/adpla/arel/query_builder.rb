module Adpla
  module Arel
    class QueryBuilder
      attr_reader :query_opts, :aliases, :table
      def initialize(big_table)
        @query_opts = {}
        @aliases = {}
        @table = big_table
        if big_table.view?
          big_table.view_constraints.each do |vc|
            add_where_query(vc)
          end
          filters=(big_table.view_projections)
        end
      end
      def fields=(value)
        @query_opts[:fields] = value
      end
      def select(arel_nodes=nil)
        arel_nodes = [arel_nodes].compact unless arel_nodes.respond_to? :each
        arel_nodes.each.select {|an| ::Arel::SqlLiteral === an}.each do |n|
          select_val = n.to_s.split(" AS ")
          add_field(select_val[0])
          aliases[select_val[0]] = select_val[1] if select_val[1]
        end
      end

      def add_field(field_name)
        return unless field_name
        query_opts[:fields] ||= ""
        query_opts[:fields] << ',' << field_name
        query_opts[:fields].sub!(/^,/,'')
      end        

      def add_facet(field_name)
        return unless field_name
        field_name = field_name.clone
        field_name.sub!(/^filters\./,'')
        if query_opts[:facets]
          query_opts[:facets] = Array(query_opts[:facets]) << field_name.to_sym
        else
          query_opts[:facets] = field_name.to_sym
        end
      end        

      def where(arel_nodes)
        arel_nodes.children.each do |node|
          add_where_query(node)
        end
      end

      def add_where_query(node)
        case node
          when Array
            node.each {|n| add_where_query(n)}
          when ::Arel::Nodes::Equality
            if @query_opts[node.left.name.to_sym]
              @query_opts[node.left.name.to_sym] = (Array(@query_opts[node.left.name.to_sym]) + Array(node.right)).uniq
            else
              vals = Array(node.right).uniq
              @query_opts[node.left.name.to_sym] = (vals[1] ? vals : vals[0])
            end
          when ::Arel::Nodes::Grouping
            n = node.expr
            if ::Arel::Nodes::Binary === n
              prefix = nil
              prefix = "NOT" if (::Arel::Nodes::NotEqual === n)
              prefix = "OR" if (::Arel::Nodes::Or === n)
              if prefix
                val = "#{prefix} #{n.right}"
                if @query_opts[n.left.name.to_sym]
                  @query_opts[n.left.name.to_sym] = Array(@query_opts[n.left.name.to_sym]) << val
                else
                  @query_opts[n.left.name.to_sym] = val
                end
              end
            end
          when Symbol # this is just a select field for facets, but we shouldn't be here!
            add_facet(node.to_s)
          else
            msg = "GOT AN UNEXPECTED NODE #{node.inspect}"
            if Rails.logger
              Rails.logger.warn msg
            else
              puts msg
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
        if value and (value = value.to_i)
          raise "Page size cannot be > 500 (#{value}" if value > 500
          @query_opts[:page_size] = value
        end
      end

      def skip(value=nil)
        if value
          @query_opts[:page] = (value.to_i / (@query_opts[:page_size] || ActiveNoSql::Relation::DEFAULT_PAGE_SIZE)) + 1
        end
      end

      def filters=(values)
        unless values.empty?
          @query_opts[:facets] = ((values[1]) ? values : values[0])
        end
      end
    end
  end
end