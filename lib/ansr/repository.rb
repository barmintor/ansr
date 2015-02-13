module Ansr
  class Repository
    attr_accessor :model, :config, :logger

    include Ansr::Configurable

    def initialize(model,config=Ansr::Configuration.new)
      @model = model
      @config = config
      configure {|c| c[:document_unique_id_param] = :id }
    end
    def model
      @model || config[:model]
    end
    ##
    # Find a single document result (by id) using the document configuration
    # @param [String] document's unique key value
    # @param [Hash] additional solr query parameters
    # @param [Proc] block to call with relation
    def find id, params = {}, &block
      rel = relation params, &block
      rel.where!(config.document_unique_id_param => id) 
      rel.load
      rel
    end

    ##
    # Execute a search query against solr
    # @param [Hash] solr query parameters
    def search params = {}, &block
      rel = relation params, &block
      rel.load
      rel
    end

    protected
    def relation params = {}, &block
      rel = block_given? ? block.call(model.spawn, config, params) : model.spawn
      rel
    end
    def logger
      @logger ||= Rails.logger if defined? Rails
    end
  end
end