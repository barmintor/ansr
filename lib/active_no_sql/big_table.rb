module ActiveNoSql
	class BigTable < ::Arel::Table
    include ActiveNoSql::Configurable

    attr_reader :klass
    alias :model :klass

    def initialize(klass, engine=nil)
      super(klass.name, engine.nil? ? klass.engine : engine)
      @klass = klass
    end

    # similar to spawn, creates a clone with added pre-selection constraints
    def view(where_clause)
      view = self.dup
      view.view!( where_clause)
      view
    end

    def view!(where_clause)
      view_constraints << where_clause
    end

    def view_constraints
      @constraints ||= []
    end

    def view_constraints=(constraints)
      @constraints = constraints
    end

    def dup2
      dup = self.class.new(@klass, self.engine)
      dup.aliases = self.aliases.dup
      dup.table_alias = self.table_alias if self.table_alias
      dup.view_constraints = self.view_constraints
      dup
    end  

    def eql? other
      super and self.view_constraints == other.view_constraints
    end
  end
end
