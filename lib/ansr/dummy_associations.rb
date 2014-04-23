module Ansr
  module DummyAssociations
    extend ActiveSupport::Concern
    module ClassMethods
      def create_reflection(macro, name, scope, options, active_record)
        case macro
        when :has_many, :belongs_to, :has_one, :has_and_belongs_to_many
          klass = options[:through] ? DummyThroughReflection : DummyAssociationReflection
          reflection = klass.new(macro, name, scope, options, active_record)
        when :composed_of
          reflection = DummyAggregateReflection.new(macro, name, scope, options, active_record)
        end

        self.reflections = self.reflections.merge(name => reflection)
        reflection
      end

      # Returns an array of AggregateReflection objects for all the aggregations in the class.
      def reflect_on_all_aggregations
        reflections.values.grep(DummyAggregateReflection)
      end

      # Returns the AggregateReflection object for the named +aggregation+ (use the symbol).
      #
      #   Account.reflect_on_aggregation(:balance) # => the balance AggregateReflection
      #
      def reflect_on_aggregation(aggregation)
        reflection = reflections[aggregation]
        reflection if reflection.is_a?(DummyAggregateReflection)
      end

      # Returns an array of DummyAssociationReflection objects for all the
      # associations in the class. If you only want to reflect on a certain
      # association type, pass in the symbol (<tt>:has_many</tt>, <tt>:has_one</tt>,
      # <tt>:belongs_to</tt>) as the first parameter.
      #
      # Example:
      #
      #   Account.reflect_on_all_associations             # returns an array of all associations
      #   Account.reflect_on_all_associations(:has_many)  # returns an array of all has_many associations
      #
      def reflect_on_all_associations(macro = nil)
        association_reflections = reflections.values.grep(DummyAssociationReflection)
        macro ? association_reflections.select { |reflection| reflection.macro == macro } : association_reflections
      end

      # Returns the DummyAssociationReflection object for the +association+ (use the symbol).
      #
      #   Account.reflect_on_association(:owner)             # returns the owner AssociationReflection
      #   Invoice.reflect_on_association(:line_items).macro  # returns :has_many
      #
      def reflect_on_association(association)
        reflection = reflections[association]
        reflection if reflection.is_a?(DummyAssociationReflection)
      end

      # Returns an array of AssociationReflection objects for all associations which have <tt>:autosave</tt> enabled.
      def reflect_on_all_autosave_associations
        reflections.values.select { |reflection| reflection.options[:autosave] }
      end
    end
    class DummyReflection < ActiveRecord::Reflection::AggregateReflection
      def initialize(macro, name, scope, options, active_record)
        super(macro, name, scope, options, active_record)
        @symbol = name
      end

      def polymorphic?
        false
      end

      def foreign_key
        @symbol # ??
      end
      def collection?
        [:has_one, :has_many, :has_and_belongs_to_many].include? macro
      end
      def validate?
        false
      end
      def association_class
        DummyAssociation
      end

      def check_validity!
        true
      end
    end
    class DummyAssociationReflection < DummyReflection; end
    class DummyAggregateReflection < DummyReflection; end
    class DummyThroughReflection < DummyReflection; end
    class DummyAssociation < ActiveRecord::Associations::Association
      def writer(*args); end
      def reader(*args)
        self
      end
      def loaded?
        true
      end
      def identifier
        nil
      end
    end
  end
end