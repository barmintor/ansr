module ActiveNoSql
  class Base < ActiveRecord::Base
    extend ActiveNoSql::Model::Methods
    extend ActiveNoSql::Configurable
    extend ActiveNoSql::QueryMethods
    extend ActiveNoSql::ArelMethods
    include ActiveNoSql::Sanitization

    self.abstract_class = true
    
    def initialize doc={}, options={}
      super(filter_source_hash(doc), options)
      @source_doc = doc
    end

    def filter_source_hash(doc)
      fields = self.class.model().table().fields()
      filtered = doc.select do |k,v|
        fields.include? k.to_sym 
      end
      filtered.with_indifferent_access
    end

    def [](key)
      @source_doc[key]
    end

  end
end