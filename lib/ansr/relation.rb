require 'yaml'
require 'kaminari'
module Ansr
  class Relation < ::ActiveRecord::Relation
    attr_reader :response
    attr_accessor :filters, :count, :context, :resource
    ::ActiveRecord::Relation::VALID_UNSCOPING_VALUES << :facet << :spellcheck
    ::ActiveRecord::Relation::SINGLE_VALUE_METHODS << :spellcheck
    DEFAULT_PAGE_SIZE = 10
    
    include Sanitization::ClassMethods
    include QueryMethods
    include ::Kaminari::PageScopeMethods

    alias :start :offset_value
    
    def initialize(klass, table, values = {})
      raise "Cannot search nil model" if klass.nil?
      super(klass, table, values)
    end

    def resource
      rsrc = @klass.name.downcase
      rsrc << ((rsrc =~ /s$/) ? 'es' : 's')
      rsrc.to_sym
    end

    def default_limit_value
      DEFAULT_PAGE_SIZE
    end

    # Overrides Rails' default hashing, FIXME?
    def values
      @values
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
      self.offset_value=value
      self
    end

    def count()
      self.load
      @response.count
    end

    def total
      count
    end
    alias :total_count :total

    def max_pages
      (total.to_f / limit_value).ceil
    end

    # override to parse filters from response 
    def facets_from(response)
      {} and raise "this is a dead method!"
    end

    # override to parse docs from response
    def docs_from(response)
      []
    end

    def facets
      if loaded?
        @facet_cache = facets_from(response)
      else
        @facet_cache ||= begin 
          query = self.limit(0)
          query.load
          query.facets
        end
      end
    end

    def spawn
      s = self.class.new(@klass, @table, @values.dup)
      s.references!(references_values())
      s
    end

    def grouped?
      false
    end

    def group_by(key=self.group_values.first)
      []
    end

    def to_nosql
      spawn.to_nosql!
    end

    def to_nosql!
      ansr_query(arel, bind_values)
    end

    private

    # override to prevent default selection of all fields
    def build_select(arel, selects)
      unless selects.empty?
        @implicit_readonly = false
        arel.project(*selects)
      #else
      #  arel.project(@klass.arel_table[Arel.star])
      end
    end


    def exec_queries
      default_scoped = with_default_scope

      if default_scoped.equal?(self)
        @response = model.find_by_nosql(arel, bind_values)
        @records = docs_from(@response).collect do |d|
          model.new(d)
        end

        # this is ceremonial, it's always true
        readonly = readonly_value.nil? || readonly_value
        @records.each { |record| record.readonly! } if readonly
      else
        @records = default_scoped.to_a
      end

      self.limit_value = default_limit_value unless self.limit_value
      self.offset_value = 0 unless self.offset_value
      @filter_cache = nil # unload any cached filters
      @loaded = true
      @records
    end
  end

end