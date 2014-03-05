module ActiveNoSql
  class Base < ActiveRecord::Base
    extend ActiveNoSql::Model::Methods
    extend ActiveNoSql::Configurable
    extend ActiveNoSql::QueryMethods
    extend ActiveNoSql::ArelMethods
    include ActiveNoSql::Sanitization

    self.abstract_class = true
    
    def initialize doc={}
      @doc = doc
    end

    def [](key)
      @doc[key]
    end

    def readonly!
    end
  end
end