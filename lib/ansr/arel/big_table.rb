require 'arel'
module Ansr
  module Arel
  	class BigTable < ::Arel::Table
      attr_reader :fields, :facets, :sorts


      attr_reader :klass
      alias :model :klass

      def initialize(klass, engine=nil)
        super(klass.name, engine.nil? ? klass.engine : engine)
        @klass = klass.model
        @fields = []
        @facets = []
        @sorts = []
        @field_configs = {}
      end

      def [] name
        name = (name.respond_to? :name) ? name.name.to_sym : name.to_sym
        (@field_configs.include? name) ? Ansr::Arel::ConfiguredField.new(self, name, @field_configs[name]) : ::Arel::Attribute.new( self, name)
      end

      def configure_fields
        if block_given?
          yield @field_configs
        end
      end
    end
  end
end
