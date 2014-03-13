# a class to pretend the unfindable "associations" are real models
module Adpla
	module Model
    class PseudoAssociate
      def initialize(doc = {})
        @doc = doc.with_indifferent_access
      end

      def method_missing(name, *args)
        @doc[name] or super
      end
    end
  end
end
