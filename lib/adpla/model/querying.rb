require 'active_record'
module Adpla
  module Model
  	module Querying
      include Adpla::Configurable
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

      FIELDS = [
        # can we list the fields from the DPLA v2 api?
      ]

      FACETS = [
        :"sourceResource.contributor",
        :"sourceResource.date.begin",
        :"sourceResource.date.end",
        :"sourceResource.language.name",
        :"sourceResource.language.iso639",
        :"sourceResource.format",
        :"sourceResource.stateLocatedIn.name",
        :"sourceResource.stateLocatedIn.iso3166-2",
        :"sourceResource.spatial.name",
        :"sourceResource.spatial.country",
        :"sourceResource.spatial.region",
        :"sourceResource.spatial.county",
        :"sourceResource.spatial.state",
        :"sourceResource.spatial.city",
        :"sourceResource.spatial.iso3166-2",
        :"sourceResource.spatial.coordinates",
        :"sourceResource.subject.@id",
        :"sourceResource.subject.name",
        :"sourceResource.temporal.begin",
        :"sourceResource.temporal.end",
        :"sourceResource.type",
        :"hasView.@id",
        :"hasView.format",
        :"isPartOf.@id",
        :"isPartOf.name",
        :"isShownAt",
        :"object",
        :"provider.@id",
        :"provider.name",
      ]

      SORTS = [
        :"id",
        :"@id",
        :"sourceResource.id",
        :"sourceResource.contributor",
        :"sourceResource.date.begin",
        :"sourceResource.date.end",
        :"sourceResource.extent",
        :"sourceResource.language.name",
        :"sourceResource.language.iso639",
        :"sourceResource.format",
        :"sourceResource.stateLocatedIn.name",
        :"sourceResource.stateLocatedIn.iso3166-2",
        :"sourceResource.spatial.name",
        :"sourceResource.spatial.country",
        :"sourceResource.spatial.region",
        :"sourceResource.spatial.county",
        :"sourceResource.spatial.state",
        :"sourceResource.spatial.city",
        :"sourceResource.spatial.iso3166-2",
        :"sourceResource.spatial.coordinates",
        :"sourceResource.subject.@id",
        :"sourceResource.subject.type",
        :"sourceResource.subject.name",
        :"sourceResource.temporal.begin",
        :"sourceResource.temporal.end",
        :"sourceResource.title",
        :"sourceResource.type",
        :"hasView.@id",
        :"hasView.format",
        :"isPartOf.@id",
        :"isPartOf.name",
        :"isShownAt",
        :"object",
        :"provider.@id",
        :"provider.name",
      ]

      def filter_values
        @values[:filter] || []
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
        unless args.empty?
          filter_where = build_where(args)
          filter_where.each do |fnode|
            filter_name = (::Arel::Nodes::Binary === fnode) ? fnode.left.name.to_sym : fnode.to_sym
            if FACETS.include? filter_name
              self.filter_values += filter_where
            else
              raise "#{filter_name} is not a filterable value"
            end
          end
        end
        self
      end

      def all_filter_fields
        FACETS
      end

      def all_sort_fields
        SORTS
      end

      def find(id)
        klass = (Adpla::Relation === self) ? @klass : self

        resource = klass.name.downcase.to_sym
        response = YAML.load(@api.send(resource, id)) || {}
        if response['count'] != 1
          raise 'Bad ID'
        end
        klass.new(response['docs'].first)
      end

      def spawn
        if Adpla::Relation === self
          Adpla::Relation.new(@klass, self.api, @values.dup)
        else
          Adpla::Relation.new(self, self.api, {})
        end
      end

      def table
        arel_table
      end

      def arel_table
        @big_table ||= Adpla::Arel::BigTable.new({:fields => FIELDS, :filters => FACETS, :sorts => SORTS})
      end

      def with_default_scope #:nodoc:
        if default_scoped? && default_scope = klass.send(:build_default_scope)
          default_scope = default_scope.merge(self)
          default_scope.default_scoped = false
          default_scope
        else
          self
        end
      end

      # Returns the Arel object associated with the relation.
      # duplicated to respect access control
      def arel # :nodoc:
        @arel ||= build_arel
      end

      private
      # Like #arel, but ignores the default scope of the model.
      def build_arel
        arel = Adpla::Arel::AdplaQuery.new(self.arel_table)

        collapse_wheres(arel, (where_values - ['']).uniq)

        arel.take(limit_value) if limit_value
        arel.skip(offset_value) if offset_value

        build_order(arel)

        build_select(arel, select_values.uniq)
        build_filter(arel, filter_values.uniq)
        collapse_wheres(arel, (filter_values - ['']).uniq)
        arel
      end

      def collapse_wheres(arel, wheres)
        predicates = wheres.map do |where|
          next where if ::Arel::Nodes::Equality === where
          where if String === where
          ::Arel::Nodes::Grouping.new(where)
        end

        arel.where(::Arel::Nodes::And.new(predicates)) if predicates.present?
      end

      def build_where(opts, other = [])
        result = case opts
          when String, Array
            #TODO: Consider sanitization requirements
            values = ((Hash === other.first) ? other.first.values : other)

            [other.empty? ? opts : ([opts] + other)]
          when Hash
            attributes = opts.dup

            Adpla::Arel::PredicateBuilder.build_from_hash(klass, attributes)
          else
            [opts]
        end
        result
      end

      def build_select(arel, select_values)
        selects = []
        select_values.inject(selects) do |memo, select|
          if select.is_a? String
            p = select.split(/\s+AS\s+/)
            if p[1]
              arel.aliases[p[0]] = p[1]
            end
            memo << p[0]
          else
            memo << select
          end
          memo
        end
        arel.fields = selects.join(',') unless selects.empty?
      end

      def build_filter(arel, filter_values)
        filters = []
        filter_values.each do |filter|
          if ::Arel::Nodes::Equality === filter
            filters << filter.left.name.to_sym
          else
            filters << filter.to_sym
          end
        end
        arel.filters = filters.uniq
      end
  	end
  end
end