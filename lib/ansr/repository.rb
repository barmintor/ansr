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
      rel.where!(q: params[:q]) if params[:q]
      rel.load
      rel
    end

    protected
    def relation params = {}, &block
      qt = (params.fetch(:qt, config.document_solr_request_handler))
      rel = qt ? model.as(qt) : model.spawn
      rel = self.instance_eval(block,rel) if block_given?
      path = config.document_solr_path || config.solr_path
      rel.from!(path) if path
      rel
    end
    def logger
      @logger ||= Rails.logger if defined? Rails
    end
  end
end