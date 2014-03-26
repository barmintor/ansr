module Ansr::Blacklight
  class Relation < Ansr::Relation
  	delegate :blacklight_config, to: :model
    
    # some compatibility aliases that should go away to properly genericize
    alias :facets :filters

    delegate :docs, to: :response
    delegate :params, to: :response

    # overrides for query response handling
    def docs_from(response)
      response.docs
    end

    def filters_from(response)
      response.facets
    end

    def count
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
      (super || default_limit_value) + 1
    end
  end
end