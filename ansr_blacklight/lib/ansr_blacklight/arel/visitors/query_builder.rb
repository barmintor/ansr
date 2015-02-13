module Ansr::Blacklight::Arel::Visitors
  class QueryBuilder < Ansr::Arel::Visitors::QueryBuilder
  	include Ansr::Blacklight::RequestBuilders
    attr_reader :solr_request, :path
    
    def initialize(table)
      super(table)
      @solr_request = Ansr::Blacklight::Solr::Request.new
      table.configure_fields.each do |k,v|
        unless v[:select].blank?
          v[:select].each do |sk, sv|
            key = "f.#{k}.#{sk}".to_sym
            @solr_request[key] = sv
          end
        end
      end
      @path = table.name || 'select'
    end

    public
    def query_opts
    	solr_request
    end

    # determines whether multiple values should accumulate or overwrite in merges
    def multiple?(field_key)
      true
    end

    def visit_String o, a
      case a
      when Ansr::Arel::Visitors::From
        query_opts.path = o
      when Ansr::Arel::Visitors::Filter
        filter_field(o.to_sym)
      when Ansr::Arel::Visitors::Order
        order(o)
      when Ansr::Arel::Visitors::ProjectionTraits
        select_val = o.to_s.split(" AS ")
        field(select_val[0].to_sym)
        if select_val[1]
          query_opts.aliases ||= {}
          query_opts.aliases[select_val[0]] = select_val[1]
        end
      else
        raise "visited String \"#{o}\" with #{a.to_s}"
      end
    end


    def visit_Arel_Nodes_TableAlias(object, attribute)
      solr_request[:qt] = object.name.to_s
      opts = {qt: object.name.to_s}
      if (cf = table[object.name]).is_a? Ansr::Arel::ConfiguredField
        opts.merge!(cf.config.fetch(:query,{}))
      end
      solr_request.merge!(opts)
      visit object.relation, attribute
    end

    def visit_Ansr_Arel_Nodes_ProjectionTraits(object, attribute)
      solr_request[:wt] = object.wt if object.wt
      solr_request[:defType] = object.defType if object.defType
      visit(object.expr, Ansr::Arel::Visitors::ProjectionTraits.new(attribute))
    end

    def visit_Arel_SqlLiteral(n, attribute)
      select_val = n.to_s.split(" AS ")
      if Ansr::Arel::Visitors::Filter === attribute
        solr_request.append_facet_fields(select_val[0].to_sym)
      else
        field(select_val[0].to_sym)
        if select_val[1]
          query_opts.aliases ||= {}
          query_opts.aliases[select_val[0]] = select_val[1]
        end
      end
    end

    def from(value)
      if value.respond_to? :name
        solr_request.path = value.name
      else
        solr_request.path = value.to_s
      end
      self.table=value if (value.is_a? Ansr::Arel::BigTable)
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
      old = solr_request[:"facet.field"] ? Array(solr_request[:"facet.field"]) : []
      fields = Array(field_name).delete_if {|x| old.include? x}
      solr_request.append_facet_fields(fields)
    end

    def visit_Arel_Nodes_Equality(object, attribute)
      field_key = (object.left.respond_to? :expr) ? field_key_from_node(object.left.expr) : field_key_from_node(object.left)
      opts = {}
      opts.merge!(local_field_params(field_key))
      opts.merge!(object.left.config.fetch(:local,{})) if object.left.respond_to? :config
      if Ansr::Arel::Visitors::Filter === attribute or Ansr::Arel::Nodes::Filter === object.left
        add_filter_fq_to_solr(solr_request, {field_key => object.right}, opts)
      else
        # check the table for configured fields
        add_query_to_solr(field_key, object.right, opts)
      end
    end

    def visit_Arel_Nodes_NotEqual(object, attribute)
    end

    def visit_Arel_Nodes_Or(object, attribute)
    end

    def visit_Arel_Nodes_Grouping(object, attribute)
      visit object.expr, attribute
    end

    def visit_Arel_Nodes_Group(object, attribute)
      solr_request[:group] = object.expr.to_s
    end

    def visit_Ansr_Arel_Nodes_Facet(object, attribute)
      name = object.expr
      name = name.name if name.respond_to? :name
      default = object.pivot || object.query
      if name == ::Arel.star
        prefix = "facet."
        default = true
      else
        prefix = "f.#{name}.facet."
      end
      # there's got to be a helper for this
      if object.pivot
        solr_request.append_facet_pivot with_ex_local_param(object.ex, Array(object.pivot).join(","))
      elsif object.query
        solr_request.append_facet_query object.query.map { |k, x| with_ex_local_param(object.ex, x[:fq]) }
      else
        object.opts.each do |att, value|
          solr_request["#{prefix}#{att.to_s}".to_sym] = value.to_s unless att == :ex
        end
        solr_request.append_facet_fields with_ex_local_param(object.ex, name.to_sym) unless default
      end
    end

    def visit_Ansr_Arel_Nodes_Spellcheck(object, attribute)
      unless object.expr == false
        solr_request[:spellcheck] = object.expr.to_s
      end
      object.opts.each do |att, val|
        solr_request["spellcheck.#{att.to_s}".to_sym] = val if att != :select
      end
    end

    def visit_Ansr_Arel_Nodes_Highlight(object, attribute)
      unless object.expr == false or object.expr == true
        solr_request[:hl] = object.expr.to_s
      end
      object.opts.each do |att, val|
        solr_request["hl.#{att.to_s}".to_sym] = val if att != :select
      end
    end

    def order(*arel_nodes)
      direction = nil
      nodes = []
      arel_nodes.inject(nodes) do |c, n|
        if ::Arel::Nodes::Ordering === n
          c << n
        elsif n.is_a? String
          _ns = n.split(/,\s*/)
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
          if solr_request[:sort_by]
            solr_request[:sort_by] = Array[solr_request[:sort_by]] << node.expr.name
          else
            solr_request[:sort_by] = node.expr.name
          end
          direction = :asc if (::Arel::Nodes::Ascending === node and direction)
          direction = :desc if (::Arel::Nodes::Descending === node)
        end
      end
      solr_request[:sort_order] = direction if direction
    end

    def visit_Arel_Nodes_Limit(object, attribute)
      value = object.expr
      if value and (value = value.to_i)
        raise "Page size cannot be > 500 (#{value}" if value > 500
        solr_request[:rows] = value.to_s
      end
    end

    def visit_Arel_Nodes_Offset(object, attribute)
      value = object.expr
      if value
        solr_request[:start] = value.to_s
      end
    end        

  end    
end