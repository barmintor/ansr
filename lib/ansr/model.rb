module Ansr
  module Model
  	module Methods
      def spawn
        s = Ansr::Relation.new(model(), table())
        s.references!(references())
      end

      def inherited(subclass)
        super
        # a hack for sanitize sql overrides to work, and some others where @klass used in place of klass()
        subclass.instance_variable_set("@klass", subclass)
        # a hack for the intermediate abstract model classes to work with table_name
        subclass.instance_variable_set("@table_name", subclass.name)
      end

      def model
        m = begin
          instance_variable_get "@klass"
        end
        raise "#{name()}.model() -> nil" unless m
        m
      end

      def references
        []
      end

      def table
        raise 'Implementing classes must provide a BigTable reader'
      end

      def table=(table)
        raise 'Implementing classes must provide a BigTable writer'
      end

      def engine
        model()
      end

	    def model
	      @klass
	    end

	    def build_default_scope
        Ansr::Relation.new(model(), table())
	    end

      def view(*wheres)
        return ViewProxy.new(model(), *wheres)
      end
    end

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
          arel = arel.intersect filter_context
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

    require 'ansr/model/connection'
    require 'ansr/model/connection_handler'
  end
end