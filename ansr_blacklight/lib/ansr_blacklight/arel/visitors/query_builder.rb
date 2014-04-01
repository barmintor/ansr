module Ansr::Blacklight::Arel::Visitors
  class QueryBuilder < Ansr::Arel::Visitors::QueryBuilder
    #include Blacklight::SolrHelper
    #include Blacklight::RequestBuilders
  	include Ansr::Blacklight::RequestBuilders
    attr_reader :blacklight_config, :solr_request
    
    def initialize(table, blacklight_config)
      super(table)
      @blacklight_config = blacklight_config
      @solr_request = Ansr::Blacklight::Solr::Request.new
      default_solr_parameters(@solr_request, nil)
      add_solr_fields_to_query(@solr_request, nil)
    end

    ## Below Copied from Blacklight::SolrHelper ##
    private

    def should_add_to_solr field_name, field
      field.include_in_request || (field.include_in_request.nil? && blacklight_config.add_field_configuration_to_solr_request)
    end

    ## Above Copied from Blacklight::SolrHelper ##
    ## Below copied from Blacklight::SearchFields ##
    def search_field_def_for_key(key)
      blacklight_config.search_fields[key]
    end
    ## Above copied from Blacklight::SearchFields ##

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
      else
        raise "visited String \"#{o}\" with #{a.to_s}"
      end
    end


    def visit_Arel_Nodes_TableAlias(object, attribute)
      solr_request[:qt] = object.name.to_s
      visit object.relation, attribute
    end

    def visit_Ansr_Arel_Nodes_ProjectionTraits(object, attribute)
      solr_request[:wt] = object.wt if object.wt
      solr_request[:defType] = object.defType if object.defType
      visit(object.expr, attribute)
    end

    def visit_Arel_SqlLiteral(n, attribute)
      select_val = n.to_s.split(" AS ")
      if Ansr::Arel::Visitors::Filter === attribute
        add_facetting_to_solr(solr_request, "facet.field" => select_val[0].to_sym)
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
      field_names = (old + Array(field_name)).uniq
      if field_names[0]
        solr_request[:"facet.field"] = field_names[1] ? field_names : field_names[0]
      end
    end

    def visit_Arel_Nodes_Equality(object, attribute)
      field_key = (object.left.respond_to? :expr) ? field_key_from_node(object.left.expr) : field_key_from_node(object.left)
      if Ansr::Arel::Visitors::Filter === attribute or Ansr::Arel::Nodes::Filter === object.left
        add_facet_fq_to_solr(solr_request, f: {field_key => object.right})
      else
        # do some q stuff
        add_query_to_solr(solr_request, search_field: field_key, q: object.right)
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
      name = object.expr.name
      filter_field(name.to_sym)
      # there's got to be a helper for this
      object.opts.each do |att, value|
        solr_request["f.#{name}.facet.#{att.to_s}".to_sym] = value.to_s
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