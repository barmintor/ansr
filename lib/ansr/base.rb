require 'active_record'
module Ansr
  class Base < ActiveRecord::Base
    include Ansr::Model
    extend Ansr::Configurable
    extend Ansr::QueryMethods
    extend Ansr::ArelMethods
    include Ansr::Sanitization
    #TODO remove the dummy associations
    include Ansr::DummyAssociations

    self.abstract_class = true
    
    def self.method
      @method ||= :get
    end

    def self.method=(method)
      @method = method
    end

    def initialize doc={}, options={}
      super(filter_source_hash(doc), options)
      @source_doc = doc
    end

    def core_initialize(attributes = nil, options = {})
      defaults = self.class.column_defaults.dup
      defaults.each { |k, v| defaults[k] = v.dup if v.duplicable? }

      @attributes   = self.class.initialize_attributes(defaults)
      @column_types_override = nil
      @column_types = self.class.column_types

      init_internals
      init_changed_attributes
      ensure_proper_type
      populate_with_current_scope_attributes

      # +options+ argument is only needed to make protected_attributes gem easier to hook.
      # Remove it when we drop support to this gem.
      init_attributes(attributes, options) if attributes

      yield self if block_given?
      run_callbacks :initialize unless _initialize_callbacks.empty?
    end

    def filter_source_hash(doc)
      fields = self.class.model().table().fields()
      filtered = doc.select do |k,v|
        fields.include? k.to_sym 
      end
      filtered.with_indifferent_access
    end

    def columns(name=self.name)
      super(name)
    end

    def [](key)
      @source_doc[key]
    end

  end
end