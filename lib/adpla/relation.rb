require 'yaml'
require 'blacklight'
module Adpla
  class Relation < ::ActiveRecord::Relation
    attr_accessor :filters, :count, :context, :api, :resource

    DEFAULT_PAGE_SIZE = 10
    
    include Adpla::Model::Querying

    attr_reader :klass, :loaded
    attr_accessor :default_scoped
    alias :model :klass
    alias :loaded? :loaded
    alias :default_scoped? :default_scoped

    def initialize(klass, api, values = {})
    	@api = api
      @klass = klass
      @values = values
    end

    def resource
      rsrc = @klass.name.downcase
      rsrc << ((rsrc =~ /s$/) ? 'es' : 's')
      rsrc.to_sym
    end

    def load
      exec_queries unless loaded?
      self
    end

    # Converts relation objects to Array.
    def to_a
      load
      @records
    end

    # Forces reloading of relation.
    def reload
      reset
      load
    end

    def empty?
      count == 0
    end

    def many?
      count > 1
    end

    def offset!(value)
      page_size = self.limit_value || DEFAULT_PAGE_SIZE
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

    def filters
      if loaded?
        @filter_cache ||= begin
          f = {}
          (@response['facets'] || {}).inject(f) do |h,(k,v)|
            if v['total'] = 0
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
      else
        @filter_cache ||= begin 
          query = self.limit(0)
          query.load
          query.filters
        end
      end
    end

    private


    def exec_queries
      default_scoped = with_default_scope

      if default_scoped.equal?(self)
        @response = YAML.load(self.api.send(self.resource, arel.query_opts)) || {}
        @records = (@response['docs'] || []).collect do |d|
          arel.aliases.each do |k,v|
            d[v] = d.delete(k)
          end
          @klass.new(d)
        end

        # this is ceremonial, it's always true
        readonly = readonly_value.nil? || readonly_value
        @records.each { |record| record.readonly! } if readonly
      else
        @records = default_scoped.to_a
      end

      self.limit_value = DEFAULT_PAGE_SIZE unless self.limit_value
      self.offset_value = 0 unless self.offset_value
      @filter_cache = nil # unload any cached filters
      @loaded = true
      @records
    end
  end


end