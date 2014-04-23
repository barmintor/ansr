require 'ansr'
module Ansr::Dpla
  module Model
    class Base < Ansr::Base
      self.abstract_class = true

  	  include Querying

      def self.inherited(subclass)
        super(subclass)
        subclass.configure do |config|
          config[:table_class] = Ansr::Dpla::Arel::BigTable
        end
      end

  		def assign_nested_parameter_attributes(pairs)
	      pairs.each do |k, v|
          v = PseudoAssociate.new(v) if Hash === v
          _assign_attribute(k, v)
        end
	    end      	
    end
  end
end