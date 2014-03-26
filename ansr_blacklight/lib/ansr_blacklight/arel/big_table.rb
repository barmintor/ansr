module Ansr::Blacklight::Arel
  class BigTable < Ansr::Arel::BigTable

    attr_accessor :blacklight_config

    def initialize(klass, engine=nil, config=nil)
      super(klass, engine)
      @blacklight_config = config
    end

    def name
      blacklight_config.solr_path
    end
    
    delegate :index_fields, to: :blacklight_config
    delegate :show_fields, to: :blacklight_config
    delegate :sort_fields, to: :blacklight_config

    def filterable
      blacklight_config.facet_fields.keys
    end

    alias_method :facets, :filterable

    def filterable?(field)
      filterable.include? field
    end

    def constrainable
      blacklight_config.search_fields.keys
    end

    def constrainable?(field)
      constrainable.include?(field)
    end

    def selectable
      show_fields.keys + index_fields.keys
    end

    def selectable?(field)
      show_fields.include? field
    end

    def fields
      (constrainable + selectable + filterable).uniq
    end

    def sortable
      sort_fields.keys
    end

    def sortable?(field)
      sort_fields.include? field
    end

    def primary_key
      @primary_key = ::Arel::Attribute.new(self, blacklight_config.document_unique_id_param.to_s)
    end
  end
end