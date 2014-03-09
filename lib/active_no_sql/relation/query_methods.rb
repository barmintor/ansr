require 'active_record'
module ActiveNoSql
  module QueryMethods
    include ActiveNoSql::Configurable
    include ActiveRecord::QueryMethods

    ActiveRecord::QueryMethods::WhereChain.class_eval <<-RUBY
      def or(opts, *rest)
        where_value = @scope.send(:build_where, opts, rest).map do |rel|
          case rel
          when ::Arel::Nodes::In
            next rel
          when ::Arel::Nodes::Equality
            # ::Arel::Nodes::OrEqual.new(rel.left, rel.right)
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

    def filter(args)
      check_if_method_has_arguments!("filter", args)
      spawn.filter!(args)
    end

    def filter!(args)
      return self if args.empty?

      filter_where = build_filter(args)
      return self unless filter_where
      filter_name = filter_name(filter_where)
      if (filter_name)
        @klass = @klass.view(*filter_where)
        model().projections += Array(filter_name)
      end
    
      self
    end

    def filter_name(expr)
      connection.sanitize_filter_name(field_name(expr))
    end

    def field_name(expr)
      if expr.is_a? Array
        return expr.collect{|x| field_name(x)}.compact
      else
        case expr
        when ::Arel::Nodes::Binary
          if expr.left.relation.name != model().name
            # oof, this is really hacky
            field_name = "#{expr.left.relation.name}.#{expr.left.name}".to_sym
          else
            field_name = expr.left.name.to_sym
          end
        when ::Arel::Attributes::Attribute
          if expr.relation.name != model().name
            # oof, this is really hacky
            field_name = "#{expr.relation.name}.#{expr.name}".to_sym
          else
            field_name = expr.name.to_sym
          end
        when ::Arel::Nodes::Unary
          if expr.expr.relation.name != model().name
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
      rel = klass.build_default_scope.where(klass.table.primary_key.name => id).limit(1)
      rel.to_a
      unless rel.to_a[0]
        raise 'Bad ID'
      end
      rel.to_a.first
    end

    def collapse_wheres(arel, wheres)
      predicates = wheres.map do |where|
        next where if ::Arel::Nodes::Equality === where
        where if String === where
        ::Arel::Nodes::Grouping.new(where)
      end

      arel.where(::Arel::Nodes::And.new(predicates)) if predicates.present?
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
          opts = (other.empty? ? opts : ([opts] + other))
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
      query = model.connection.to_nosql(arel, bind_values)
      aliases = model.connection.to_aliases(arel, bind_values)
      model.connection.execute(query, aliases)
    end
  end
end