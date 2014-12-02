module Ansr::Blacklight
  class Relation < Ansr::Relation
    include Ansr::Blacklight::SolrProjectionMethods
    ::ActiveRecord::Relation::VALID_UNSCOPING_VALUES << :defType << :wt
    ::ActiveRecord::Relation::SINGLE_VALUE_METHODS << :defType << :wt

  	delegate :blacklight_config, to: :model
    
    delegate :docs, to: :response
    delegate :params, to: :response
    delegate :facet_pivot, to: :response
    delegate :facet_queries, to: :response
    # overrides for query response handling
    def docs_from(response)
      grouped? ? [] : response.docs
    end

    def facets_from(response)
      response.facets
    end

    def total
      response.total
    end

    # overrides for weird Blacklight expectations
    def max_pages
      if Kaminari.config.respond_to? :max_pages
        nil
      else
        super
      end
    end

    def limit_value
      (super || default_limit_value)
    end

    def build_arel
      arel = super
      solr_props = {}
      solr_props[:defType] = defType_value if defType_value
      solr_props[:wt] = wt_value if wt_value
      unless solr_props.empty?
        prop_node = Ansr::Arel::Nodes::ProjectionTraits.new arel.grouping(arel.projections), solr_props
        arel.projections = [prop_node]
      end
      arel
    end

    def spelling
      loaded
      response.spelling
    end

    def grouped?
      loaded? ? response.grouped? : !group_values.blank?
    end

    def group_by(key=self.group_values.first)
      loaded
      response.group(key, model)
    end
  end
end