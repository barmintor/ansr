module ActiveNoSql
  module Model
  	module Methods
	    def model
	      self
	    end

	    def build_default_scope
        ActiveNoSql::Relation.new(self)
	    end
    end

  end
end