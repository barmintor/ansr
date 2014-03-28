require 'active_record'
module Ansr
  module QueryMethods
    include Ansr::Configurable
    include ActiveRecord::QueryMethods

    ActiveRecord::QueryMethods::WhereChain.class_eval <<-RUBY
      def or(opts, *rest)
        where_value = @scope.send(:build_where, opts, rest).map do |rel|
          case rel
          when ::Arel::Nodes::In
            ::Arel::Nodes::Or.new(rel.left, rel.right)
          when ::Arel::Nodes::Equality
            ::Arel::Nodes::Or.new(rel.left, rel.right)
          when String
            ::Arel::Nodes::Or.new(::Arel::Nodes::SqlLiteral.new(rel))
          else
            ::Arel::Nodes::Or.new(rel)
          end
        end
        @scope.where_values += where_value.flatten
        @scope
      end
    RUBY


    def filter_values
      @values[:filter] ||= []
    end

    def filter_values=(values)
      raise ImmutableRelation if @loaded
      @values[:filter] = values
    end

    def filter(expr, opts = {})
      check_if_method_has_arguments!("filter", expr)
      spawn.filter!(expr, opts)
    end

    def filter!(expr, opts = {})
      return self if expr.empty?

      filter_nodes = build_filter(expr)
      return self unless filter_nodes
      filters = []
      filter_nodes.each do |filter_node|
        case filter_node
        when ::Arel::Nodes::In, ::Arel::Nodes::Equality
          filter_node.left = Ansr::Arel::Nodes::Filter.new(filter_node.left, opts)
        when ::Arel::SqlLiteral, String, Symbol
          filter_node = Ansr::Arel::Nodes::Filter.new(::Arel::Attribute.new(model().table, filter_node.to_s), opts)
        else
          raise "unexpected filter node type #{filter_node.class}"
        end
        filters << filter_node
      end
      #filter_name = filter_name(filter_where)
      self.filter_values+= filters 
    
      self
    end

    def filter_unscoping(target_value)
      target_value_sym = target_value.to_sym

      filter_values.reject! do |rel|
        case rel
        when ::Arel::Nodes::In, ::Arel::Nodes::Equality
          subrelation = (rel.left.kind_of?(::Arel::Attributes::Attribute) ? rel.left : rel.right)
          subrelation.name.to_sym == target_value_sym
        else
          raise "unscope(filter: #{target_value.inspect}) failed: unscoping #{rel.class} is unimplemented."
        end
      end
    end

    def filter_name(expr)
      connection.sanitize_filter_name(field_name(expr))
    end

    def as(args)
      spawn.as!(args)
    end

    def as!(args)
      self.as_value= args
    end

    def as_value
      @values[:as]
    end

    def as_value=(args)
      raise ActiveRecord::ImmutableRelation if @loaded
      @values[:as] = args
    end

    def as_unscoping(*args)
      @values.delete(:as)
    end

    def highlight(expr, opts={})
      spawn.highlight!(expr, opts)
    end

    def highlight!(expr, opts = {})
      self.highlight_value= Ansr::Arel::Nodes::Highlight.new(expr, opts)
    end

    def highlight_value
      @values[:highlight]
    end

    def highlight_value=(val)
      raise ActiveRecord::ImmutableRelation if @loaded
      @values[:highlight] = val
    end

    def highlight_unscoping(*args)
      @values.delete(:highlight)
    end

    def spellcheck(expr, opts={})
      spawn.spellcheck!(expr, opts)
    end

    def spellcheck!(expr, opts = {})
      self.spellcheck_value= Ansr::Arel::Nodes::Spellcheck.new(expr, opts)
    end

    def spellcheck_value
      @values[:spellcheck]
    end

    def spellcheck_value=(val)
      raise ActiveRecord::ImmutableRelation if @loaded
      @values[:spellcheck] = val
    end

    def spellcheck_unscoping(*args)
      @values.delete(:spellcheck)
    end

    def field_name(expr)
      if expr.is_a? Array
        return expr.collect{|x| field_name(x)}.compact
      else
        case expr
        when ::Arel::Nodes::Binary
          if expr.left.relation.name != model().table.name
            # oof, this is really hacky
            field_name = "#{expr.left.relation.name}.#{expr.left.name}".to_sym
          else
            field_name = expr.left.name.to_sym
          end
        when ::Arel::Attributes::Attribute
          if expr.relation.name != model().table.name
            # oof, this is really hacky
            field_name = "#{expr.relation.name}.#{expr.name}".to_sym
          else
            field_name = expr.name.to_sym
          end
        when ::Arel::Nodes::Unary, Ansr::Arel::Nodes::Filter
          if expr.expr.relation.name != model().table.name
            # oof, this is really hacky
            field_name = "#{expr.expr.relation.name}.#{expr.expr.name}".to_sym
          else
            field_name = expr.expr.name.to_sym
          end
        else
          field_name = expr.to_sym
        end
        return field_name
      end
    end

    def all_filter_fields
      FACETS
    end

    def all_sort_fields
      SORTS
    end

    def find(id)
      klass = model()
      rel = where(klass.table.primary_key.name => id).limit(1)
      rel.to_a
      unless rel.to_a[0]
        raise 'Bad ID'
      end
      rel.to_a.first
    end

    def collapse_wheres(arel, wheres)
      predicates = wheres.map do |where|
        next where if ::Arel::Nodes::Equality === where
        where = Arel.sql(where) if String === where # SqlLiteral-ize
        ::Arel::Nodes::Grouping.new(where)
      end

      arel.where(::Arel::Nodes::And.new(predicates)) if predicates.present?
    end

    def collapse_filters(arel, filters)
      predicates = filters.map do |filter|
        next filter if ::Arel::Nodes::Equality === filter
        filter = Arel.sql(filter) if String === filter # SqlLiteral-ize
        ::Arel::Nodes::Grouping.new(filter)
      end

      arel.where(::Arel::Nodes::And.new(predicates)) if predicates.present?
    end

    # Could filtering be moved out of intersection into one arel tree?
    def build_arel
      arel = super
      collapse_filters(arel, (filter_values).uniq)
      arel.projections << @values[:spellcheck] if @values[:spellcheck]
      arel.projections << @values[:highlight] if @values[:highlight]
      arel.from arel.create_table_alias(arel.source.left, as_value) if as_value
      arel
    end      

    # cloning from ActiveRecord::QueryMethods.build_where as a first pass
    def build_filter(opts, other=[])
      case opts
        when String, Array
          #TODO: Remove duplication with: /activerecord/lib/active_record/sanitization.rb:113
          values = Hash === other.first ? other.first.values : other

          values.grep(ActiveRecord::Relation) do |rel|
            self.bind_values += rel.bind_values
          end
          opts = (other.empty? ? opts : (Array(opts) + other))
          [model().send(:sanitize_sql, opts, model().table_name)]
        when Hash
          attributes = model().send(:expand_hash_conditions_for_sql_aggregates, opts)

          attributes.keys.each do |k|
            sk = filter_name(k)
            attributes[sk] = attributes.delete(k) unless sk.eql? k.to_s
          end
          attributes.values.grep(ActiveRecord::Relation) do |rel|
            self.bind_values += rel.bind_values
          end

          ActiveRecord::PredicateBuilder.build_from_hash(model(), attributes, model().table)
        else
          [opts]
      end
    end

    def find_by_nosql(arel, bind_values)
      @ansr_query = model.connection.to_nosql(arel, bind_values)
      model.connection.execute(@ansr_query)
    end

    def ansr_qeury
      @ansr_query
    end
  end
end