module Ansr::Dpla::Arel::Visitors
  class QueryBuilder < Ansr::Arel::Visitors::QueryBuilder
    attr_reader :query_opts
    
    def initialize(table, query_opts=nil)
      super(table)
      @query_opts = query_opts ||= Ansr::Dpla::Request.new
      @query_opts.path = table.name
    end

    # determines whether multiple values should accumulate or overwrite in merges
    def multiple?(field_key)
      true
    end

    def visit_String o, a
      case a
      when Ansr::Arel::Visitors::From
        query_opts.path = o
      when Ansr::Arel::Visitors::Facet
        filter_field(o.to_sym)
      when Ansr::Arel::Visitors::Order
        order(o)
      else
        raise "visited String \"#{o}\" with #{a.to_s}"
      end
    end

    def visit_Arel_SqlLiteral(n, attribute)
      select_val = n.to_s.split(" AS ")
      case attribute
      when Ansr::Arel::Visitors::Order
        order(n.to_s)
      when Ansr::Arel::Visitors::Facet
        filter_field(select_val[0].to_sym)
      else
        field(select_val[0].to_sym)
        if select_val[1]
          query_opts.aliases ||= {}
          query_opts.aliases[select_val[0]] = select_val[1]
        end
      end
    end

    def visit_Ansr_Arel_Nodes_Filter(object, attribute)
      expr = object.expr
      case expr
      when ::Arel::SqlLiteral
        visit expr, Ansr::Arel::Visitors::Filter.new(attribute) if object.select
      when ::Arel::Attributes::Attribute
        name = object.expr.name
        name = "#{expr.relation.name}.#{name}" if expr.relation.name.to_s != table.name.to_s
        visit name, Ansr::Arel::Visitors::Filter.new(attribute) if object.select
      else
        raise "Unexpected filter expression type #{object.expr.class}"
      end
    end

    def visit_Ansr_Arel_Nodes_Facet(object, attribute)
      expr = object.expr
      case expr
      when ::Arel::SqlLiteral
        visit expr, Ansr::Arel::Visitors::Facet.new(attribute)
      when ::Arel::Attributes::Attribute
        name = object.expr.name
        name = "#{expr.relation.name}.#{name}" if expr.relation.name.to_s != table.name.to_s
        visit name, Ansr::Arel::Visitors::Facet.new(attribute) if object.select
      else
        raise "Unexpected filter expression type #{object.expr.class}"
      end
    end

    def projections
      query_opts[:fields] || []
    end

    def filter_projections
      query_opts[:facets] || []
    end


    def field(field_name)
      return unless field_name
      old = query_opts[:fields] ? Array(query_opts[:fields]) : []
      field_names = (old + Array(field_name)).uniq
      if field_names[0]
        query_opts[:fields] = field_names[1] ? field_names : field_names[0]
      end
    end

    def filter_field(field_name)
      return unless field_name
      field_name = Array(field_name)
      field_name.each {|fn| raise "#{fn} is not a facetable field" unless table.facets.include? fn.to_sym}
      old = query_opts[:facets] ? Array(query_opts[:facets]) : []
      field_names = (old + Array(field_name)).uniq
      if field_names[0]
        query_opts[:facets] = field_names[1] ? field_names : field_names[0]
      end
    end

    def add_where_clause(attr_node, val)
      field_key = field_key_from_node(attr_node)
      if query_opts[field_key]
        query_opts[field_key] = Array(query_opts[field_key]) << val
      else
        query_opts[field_key] = val
      end
    end

    # the DPLA API makes no distinction between filter and normal queries
    def visit_Arel_Nodes_Equality(object, attribute)
      add_where_clause(object.left, object.right)
    end

    def visit_Arel_Nodes_NotEqual(object, attribute)
      add_where_clause(object.left, "NOT " + object.right)
    end
    def visit_Arel_Nodes_Or(object, attribute)
      add_where_clause(object.left, "OR " + object.right)
    end

    def visit_Arel_Nodes_Grouping(object, attribute)
      visit object.expr, attribute
    end

    def visit_Arel_Nodes_Ordering(object, attribute)
      if query_opts[:sort_by]
        query_opts[:sort_by] = Array[query_opts[:sort_by]] << object.expr.name
      else
        query_opts[:sort_by] = object.expr.name
      end
      direction = :asc if (::Arel::Nodes::Ascending === object and direction)
      direction = :desc if (::Arel::Nodes::Descending === object)
      query_opts[:sort_order] = direction if direction
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
          if query_opts[:sort_by]
            query_opts[:sort_by] = Array[query_opts[:sort_by]] << node.expr.name
          else
            query_opts[:sort_by] = node.expr.name
          end
          direction = :asc if (::Arel::Nodes::Ascending === node and direction)
          direction = :desc if (::Arel::Nodes::Descending === node)
        end
      end
      query_opts[:sort_order] = direction if direction
    end

    def visit_Arel_Nodes_Limit(object, attribute)
      value = object.expr
      if value and (value = value.to_i)
        raise "Page size cannot be > 500 (#{value}" if value > 500
        query_opts[:page_size] = value
      end
    end

    def visit_Arel_Nodes_Offset(object, attribute)
      value = object.expr
      if value
        query_opts[:page] = (value.to_i / (query_opts[:page_size] || Ansr::Relation::DEFAULT_PAGE_SIZE)) + 1
      end
    end        

  end    
end