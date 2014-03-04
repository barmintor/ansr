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
        self.where_values += filter_where
        select!(filter_name)
      end
    
      self
    end

    def filter_name(filter_where)
      if filter_where.is_a? Array
        return filter_where.collect{|x| filter_name(x)}.compact
      else
        filter_name = (::Arel::Nodes::Binary === filter_where) ? filter_where.left.name.to_sym : filter_where.to_sym
        filter_name = connection.sanitize_filter_name(filter_name)
        if filter_name
          filter_name = filter_name =~ /filters\./ ? filter_name : "filters.#{filter_name.to_s}"
        end
        return filter_name
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
      resource = klass.name.downcase.to_sym
      response = YAML.load(@api.send(resource, id)) || {}
      if response['count'] != 1
        raise 'Bad ID'
      end
      klass.new(response['docs'].first)
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
          [opts]
          [@klass.send(:sanitize_sql, opts)]
        when Hash
          attributes = @klass.send(:expand_hash_conditions_for_aggregates, opts)

          attributes.keys.each do |k|
            sk = filter_name(k)
            attributes[sk] = attributes.delete(k) unless sk.eql? k.to_s
          end
          attributes.values.grep(ActiveRecord::Relation) do |rel|
            self.bind_values += rel.bind_values
          end

          ActiveRecord::PredicateBuilder.build_from_hash(klass, attributes, table)
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