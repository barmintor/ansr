module ActiveNoSql
  module Model
  	module Methods
  		def model=(klass)
  			@klass = klass
      end
	    def model
	      @klass
	    end

	    def build_default_scope
        ActiveNoSql::Relation.new(self)
	    end
    end

  end
end