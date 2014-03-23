require 'yaml'
require 'blacklight'
module Ansr::Dpla
  class Relation < ::Ansr::Relation

    def initialize(klass, table, values = {})
      raise "Cannot search nil model" if klass.nil?
      super(klass, table, values)
    end

    def empty?
      count == 0
    end

    def many?
      count > 1
    end

    def offset!(value)
      page_size = self.limit_value || default_limit_value
      if (value.to_i % page_size.to_i) != 0
        raise "Bad offset #{value} for page size #{page_size}"
      end
      self.offset_value=value
      self
    end

    def count
      self.load
      @response['count']
    end

    def filters_from(response)
      f = {}
      (response['facets'] || {}).inject(f) do |h,(k,v)|

        if v['total'] != 0
          items = v['terms'].collect do |term|
            Blacklight::SolrResponse::Facets::FacetItem.new(:value => term['term'], :hits => term['count'])
          end
          options = {:sort => 'asc', :offset => 0}
          h[k] = Blacklight::SolrResponse::Facets::FacetField.new k, items, options
        end
        h
      end
      f
    end

    def docs_from(response)
      response['docs']
    end

  end


end