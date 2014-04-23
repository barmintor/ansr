module Ansr::Blacklight::Arel
  class BigTable < Ansr::Arel::BigTable
    attr_accessor :name

    def initialize(klass, engine=nil, config=nil)
      super(klass, engine)
      @name = 'select'
      self.config(config)
    end
    
    delegate :index_fields, to: :config
    delegate :show_fields, to: :config
    delegate :sort_fields, to: :config

    def filterable
      config.facet_fields.keys
    end

    alias_method :facets, :filterable

    def filterable?(field)
      filterable.include? field
    end

    def constrainable
      index_fields.keys
    end

    def constrainable?(field)
      index_fields.include?(field)
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
      @primary_key ||= ::Arel::Attribute.new(self, config.document_unique_id_param.to_s)
    end
  end
end