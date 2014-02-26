require 'active_record'
module Adpla
  module Model
  	module Querying
      include ActiveRecord::QueryMethods

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

      def facet_values
        @values[:facet] || []
      end

      def facet_values=(values)
        raise ImmutableRelation if @loaded
        @values[:facet] = values
      end

      def facet(args)
        check_if_method_has_arguments!("facet", args)
        spawn.facet!(args)
      end

      def facet!(args)
        unless args.empty?
          facet_where = build_where(args)
          facet_where.each do |fnode|
            facet_name = fnode.left.name.to_sym
            if FACETS.include? facet_name
              self.facet_values += facet_where
            else
              raise "#{facet_name.to_s} is not a facetable value"
            end
          end
        end
        self
      end

      def all_facets
        FACETS
      end

      def sorts
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
          Adpla::Relation.new(@klass, @api, @values.dup)
        else
          Adpla::Relation.new(self.class, @api, {})
        end
      end

      def table
        arel_table
      end

      def arel_table
        @big_table ||= Adpla::Arel::BigTable.new({:fields => FIELDS, :facets => FACETS, :sorts => SORTS})
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
        build_facet(arel, facet_values.uniq)
        collapse_wheres(arel, (facet_values - ['']).uniq)
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

      def build_facet(arel, facet_values)
        facets = []
        facet_values.each do |facet|
          facets << facet.left.name.to_sym if ::Arel::Nodes::Equality === facet
        end
        arel.facets = facets.uniq
      end
  	end
  end
end