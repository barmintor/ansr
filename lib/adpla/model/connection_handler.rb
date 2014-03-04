require 'active_no_sql'
module Adpla
  module Model
    class ConnectionHandler
      def retrieve_connection(klass)
        Adpla::Arel::Connection.new(klass.table)
      end

      def retrieve_connection_pool(klass)
        klass.connection
      end

      def connected?
        true
      end
    end
  end
end