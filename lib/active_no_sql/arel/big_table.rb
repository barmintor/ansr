module ActiveNoSql
  module Arel
  	class BigTable < ::Arel::Table
      attr_reader :fields, :facets, :sorts

      include ActiveNoSql::Configurable

      attr_reader :klass
      alias :model :klass

      def initialize(klass, engine=nil)
        super(klass.name, engine.nil? ? klass.engine : engine)
        @klass = klass.model
        @fields = []
        @facets = []
        @sorts = []
      end

      def view?
        ActiveNoSql::Model::ViewProxy === model()
      end
    end
  end
end
