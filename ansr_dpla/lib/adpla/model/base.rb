require 'active_no_sql'
module Adpla
  module Model
    class Base < ActiveNoSql::Base
      self.abstract_class = true

  	  include Querying

  		def assign_nested_parameter_attributes(pairs)
	      pairs.each do |k, v|
          v = PseudoAssociate.new(v) if Hash === v
          _assign_attribute(k, v)
        end
	    end      	
    end
  end
end