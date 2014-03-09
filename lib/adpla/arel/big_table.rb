module Adpla
  module Arel
    class BigTable < ActiveNoSql::Arel::BigTable

      FIELDS = [
        # can we list the fields from the DPLA v2 api?
        # the sourceResource, originalRecord, and provider fields need to be associations, right?
        :"_id",
        :"dataProvider",
        :"sourceResource",
        :"object",
        :"ingestDate",
        :"originalRecord",
        :"ingestionSequence",
        :"isShownAt",
        :"hasView",
        :"provider",
        :"@context",
        :"ingestType",
        :"@id",
        :"id"
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
        super(klass.model())
        @fields += (opts[:fields] || FIELDS)
        @facets += (opts[:facets] || FACETS)
        @sorts += (opts[:sorts] || SORTS)
        self.config(opts[:config]) if opts[:config]
      end

    end
  end
end