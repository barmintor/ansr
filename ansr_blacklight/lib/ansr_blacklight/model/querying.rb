module Ansr::Blacklight::Model
  module Querying
  extend ActiveSupport::Concern

    module ClassMethods

      def solr
        Blacklight.solr
      end

      def build_default_scope
        rel = Ansr::Blacklight::Relation.new(model(), table()).from(blacklight_config.solr_path)
        rel
      end

      def unique_key
        blacklight_config.document_unique_id_param
      end

      def table
        @big_table ||= Ansr::Blacklight::Arel::BigTable.new(model(), nil, blacklight_config)
      end

      def table=(val)
        @big_table = val
      end

      def connection_handler
        @connection_handler ||= Ansr::Model::ConnectionHandler.new(Ansr::Blacklight::ConnectionAdapters::NoSqlAdapter)
      end

      def references
        []
      end
    end
  end
end