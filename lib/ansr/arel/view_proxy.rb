module Ansr::Arel
  # treat filters as ad-hoc views
  # currently modeled as an intersection, but perhaps could be better
  # represented by a proxy on BigTable? or a pseudo-table of filters?
  class ViewProxy
    attr_accessor :model
    def initialize(model, *wheres)
      if ViewProxy === model
        @model = model.model
        self.constraints = Array(model.constraints)
        self.projections = model.projections.dup
      else
        @model = model
      end
      if wheres[0]
        self.constraints = self.constraints + wheres
      end
    end

    def view_arel(engine, table)
      arel = ::Arel::SelectManager.new(engine, table)
      constraints.each {|c| arel.where(c) }
      arel.project projections()
      arel
    end

    def find_by_nosql(arel, bind_values)
      filter_context = nil
      if self.view?
        filter_context = view_arel(arel.engine, arel.source.left)
        arel = arel.intersect(filter_context) #Ansr::Arel::IntersectManager.new(arel.engine, arel.intersect(filter_context))
      end
      model.find_by_nosql(arel, bind_values)
    end

    def expand_hash_conditions_for_aggregates(attrs)
      # this is a protected method in the AR sanitization module
      model.send(:expand_hash_conditions_for_aggregates, attrs)
    end

    def constraints
      @constraints ||= []
    end

    def constraints=(values)
      @constraints = Array === (values) ? values : Array(values)
    end

    def projections
      @projections ||= []
    end

    def projections=(values)
      @projections = Array === (values) ? values : Array(values)
    end

    def view?
      (@constraints and @constraints.length > 0) or (@projections and @projections.length > 0)
    end

    def view(*wheres)
      ViewProxy.new(self, wheres)
    end

    def self.===(other)
      other.is_a? ViewProxy
    end

    def connection_handler=(handler)
      @connection_handler = handler
    end

    def build_default_scope
      model().all
    end

    # model delegations
    def connection
      model().connection
    end

    def name
      model().name
    end

    def table
      model().table
    end

    def arel_table
      model().arel_table
    end

    def current_scope=(scope)
      model().current_scope=(scope)
    end

    def current_scope
      model().current_scope
    end

    def method_missing(method, *args, &block)
      model().send(method, *args, &block)
    end
  end
end