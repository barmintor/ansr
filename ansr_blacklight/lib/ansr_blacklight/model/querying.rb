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

      def table
        @big_table ||= Ansr::Arel::BigTable.new(model(), nil)
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