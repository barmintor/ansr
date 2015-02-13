module Ansr
  module Blacklight
    class Repository < Ansr::Repository

      def initialize(model,config=Ansr::Configuration.new)
        super
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
        rel = super
        qt = (params.fetch(:qt, config.document_solr_request_handler))
        rel.as!(qt) if qt
        path = config.document_solr_path || config.solr_path
        rel.from!(path) if path
        rel
      end
      def logger
        @logger ||= Rails.logger if defined? Rails
      end
    end
  end
end