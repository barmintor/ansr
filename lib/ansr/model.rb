module Ansr
  module Model
  	module Methods
      def spawn
        s = build_default_scope
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
        return Ansr::Arel::ViewProxy.new(model(), *wheres)
      end
    end

    require 'ansr/model/connection_handler'
  end
end