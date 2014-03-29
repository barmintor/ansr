require 'arel'
module Ansr
  module Arel
  	class BigTable < ::Arel::Table
      attr_reader :fields, :facets, :sorts

      include Ansr::Configurable

      attr_reader :klass
      alias :model :klass

      def initialize(klass, engine=nil)
        super(klass.name, engine.nil? ? klass.engine : engine)
        @klass = klass.model
        @fields = []
        @facets = []
        @sorts = []
      end

    end
  end
end
