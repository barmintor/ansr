module ActiveNoSql
  class BigTable < ::Arel::Table
    include ActiveNoSql::Configurable

    attr_reader :klass
    alias :model :klass
    alias :spawn :dup

    def initialize(klass, engine=nil)
      _e = (engine.nil? ? klass.engine : engine)
      super(klass.name, _e)
      @klass = klass
    end

    # similar to spawn, creates a clone with added pre-selection constraints
    def view(where_clause)
      view = self.dup
      view.view!(where_clause)
      view
    end

    def view!(where_clause)
      filter_name = filter_name(where_clause)
      if filter_name
        view_constraints << where_clause
        view_projections << filter_name
      end
    end

    def view_constraints
      @constraints ||= []
    end

    def view_constraints=(constraints)
      @constraints = Array(constraints)
      #@constraints = constraints
      #puts "@constraints = #{constraints.to_s}"
    end

    def view_projections
      @projections ||= []
    end

    def view_projections=(projections)
      @projections = Array(projections)
      #@projections = projections
    end

    def view?
      return true if @constraints and @constraints.length > 0
      return true if @projections and @projections.length > 0
      return false
    end

    def filter_name(filter_where)
      case filter_where
      when Array
        return filter_where.collect{|x| filter_name(x)}.compact
      when Symbol
        return sanitize_filter_name(filter_where)
      else
        filter_name = (::Arel::Nodes::Binary === filter_where) ? filter_where.left.name.to_sym : filter_where.to_sym
        return sanitize_filter_name(filter_name)
      end
    end

    def dup
      puts "spawning new table"
      dupl = self.class.new(@klass, self.engine)
      dupl.aliases = self.aliases.dup
      dupl.table_alias = self.table_alias if self.table_alias
      dupl.view_constraints = [] + self.view_constraints
      dupl.view_projections = [] + self.view_projections
      dupl
    end

    def references
      []
    end

    def columns(*args)
      return args # this is a misbehaving deprecated method in the superclass
    end

    # noop
    def sanitize_filter_name(filter_value)
      filter_value
    end

    def eql? other
      super and self.view_constraints == other.view_constraints and self.view_projections == other.view_projections
    end
  end
end
