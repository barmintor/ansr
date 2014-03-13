module Ansr
  module Model
    class ConnectionHandler
      def initialize(connection_class)
        @connection_class = connection_class
      end
      def retrieve_connection(klass)
        @connection_class.new(klass)
      end

      def retrieve_connection_pool(klass)
        retrieve_connection(klass)
      end

      def connected?(klass)
        true
      end
    end
  end
end