module Ansr::Blacklight
  class Base < Ansr::Base
    include Ansr::Blacklight::Model::Querying

    self.abstract_class = true

    self.primary_key = 'id'

    def self.solr_search_params_logic
    	@solr_search_params_logic || []
    end

    def self.solr_search_params_logic=(vals)
      @solr_search_params_logic=vals
    end

    def self.build_default_scope
      rel = super
      solr_search_params_logic.each {|method| rel = self.send(method, rel)}
      rel
    end
  end
end