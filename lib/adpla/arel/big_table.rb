module Adpla
  module Arel
    class BigTable < ActiveNoSql::BigTable
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

      REFERENCES = [:sourceResource, :hasView, :isPartOf, :provider]

      def initialize(klass, engine=nil, opts={})
        super(klass, engine)
        @fields = (opts[:fields] || FIELDS).dup
        @facets = (opts[:facets] || FACETS).dup
        @sorts = (opts[:sorts] || SORTS).dup
        self.config(opts[:config]) if opts[:config]
      end
      
      def [](name)
        ::Arel::Attribute.new(self, name)
      end

      def table_exists?(*args)
        true
      end

      def references
        REFERENCES
      end

      def sanitize_filter_name(filter_value)
        if filter_value.is_a? Array
          return filter_value.collect {|x| sanitize_filter_name(x)}.compact
        else
          if BigTable::FACETS.include? filter_value.to_sym
            return filter_value
          else
            raise "#{filter_value} is not a facetable field"
            #Rails.logger.warn "Ignoring #{filter_value} (not a filterable field)" if Rails.logger
            #return nil
          end
        end
      end
    end
  end
end