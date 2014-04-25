module Ansr::Blacklight::Model
  module Querying
  extend ActiveSupport::Concern

    module ClassMethods

      def solr
        Ansr::Blacklight.solr
      end

      def build_default_scope
        rel = Ansr::Blacklight::Relation.new(model(), table())
        rel
      end

      def unique_key
        table().unique_key
      end

      def default_connection_handler
        @default_connection_handler ||= Ansr::Model::ConnectionHandler.new(Ansr::Blacklight::ConnectionAdapters::NoSqlAdapter)
      end

      def references
        []
      end
      def ansr_query(*args)
        ansr_query = super(*args)
        ansr_query.http_method = args[2] if args[2]
        ansr_query
      end
    end
  end
end