module Ansr
  class Base < ActiveRecord::Base
    extend Ansr::Model::Methods
    extend Ansr::Configurable
    extend Ansr::QueryMethods
    extend Ansr::ArelMethods
    include Ansr::Sanitization

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