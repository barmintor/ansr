require 'arel'
module Ansr
  module Arel
  	class BigTable < ::Arel::Table
      attr_writer :primary_key
      attr_reader :fields, :facets, :sorts


      attr_reader :klass
      alias :model :klass

      def self.primary_key
        @primary_key ||= 'id'
      end

      def self.primary_key=(key)
        @primary_key = key
      end

      def initialize(klass, engine=nil)
        super(klass.name, engine.nil? ? klass.engine : engine)
        @klass = klass.model
        @fields = []
        @facets = []
        @sorts = []
        @field_configs = {}
      end

      def primary_key
        @primary_key ||= ::Arel::Attribute.new( self, self.class.primary_key )
      end

      def primary_key=(key)
        @primary_key = ::Arel::Attribute.new( self, key.to_s )
      end

      def [] name
        name = (name.respond_to? :name) ? name.name.to_sym : name.to_sym
        (@field_configs.include? name) ? Ansr::Arel::ConfiguredField.new(self, name, @field_configs[name]) : ::Arel::Attribute.new( self, name)
      end

      def configure_fields
        if block_given?
          yield @field_configs
        end
        @field_configs
      end
      def fields
        if block_given?
          yield @fields
        end
        @fields
      end
      def facets
        if block_given?
          yield @facets
        end
        @facets
      end
      def sorts
        if block_given?
          yield @sorts
        end
        @sorts
      end
    end
  end
end
