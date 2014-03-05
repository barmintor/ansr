module ActiveNoSql
	class BigTable < ::Arel::Table
    include ActiveNoSql::Configurable

    attr_reader :klass
    alias :model :klass

    def initialize(klass, engine=nil)
      super(klass.name, engine.nil? ? klass.engine : engine)
      @klass = klass.model
    end

    def view?
      ActiveNoSql::Model::ViewProxy === model()
    end

  end
end
