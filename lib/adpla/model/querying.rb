require 'active_record'
module Adpla
  module Model
  	module Querying
    extend ActiveSupport::Concern

      module ClassMethods
        def api
          @api ||= begin
            a = (config[:api] || Adpla::Api).new
            a.config(self.config)
            a
          end
        end

        def api=(api)
          @api = api
        end

        def table
          @big_table ||= Adpla::Arel::BigTable.new(model(), {:config => config()})
        end

        def table=(val)
          @big_table = val
        end

        def connection_handler
          @connection_handler ||= ActiveNoSql::Model::ConnectionHandler.new(Adpla::Arel::Connection)
        end

        def references
          ['provider', 'object']
        end
      end
    end
  end
end