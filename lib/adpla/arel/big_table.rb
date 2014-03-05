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

      def initialize(klass, opts={})
        super(klass)
        @fields = (opts[:fields] || FIELDS).dup
        @facets = (opts[:facets] || FACETS).dup
        @sorts = (opts[:sorts] || SORTS).dup
        self.config(opts[:config]) if opts[:config]
      end
      
      def [](name)
        ::Arel::Attribute.new(self, name)
      end

    end
  end
end