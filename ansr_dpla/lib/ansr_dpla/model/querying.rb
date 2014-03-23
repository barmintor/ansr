require 'active_record'
module Ansr::Dpla
  module Model
  	module Querying
    extend ActiveSupport::Concern

      module ClassMethods
        def build_default_scope
          Ansr::Dpla::Relation.new(model(), table())
        end

        def api
          @api ||= begin
            a = (config[:api] || Ansr::Dpla::Api).new
            a.config(self.config)
            a
          end
        end

        def api=(api)
          @api = api
        end

        def table
          @big_table ||= Ansr::Dpla::Arel::BigTable.new(model(), {:config => config()})
        end

        def table=(val)
          @big_table = val
        end

        def connection_handler
          @connection_handler ||= Ansr::Model::ConnectionHandler.new(Ansr::Dpla::ConnectionAdapters::NoSqlAdapter)
        end

        def references
          ['provider', 'object']
        end
      end
    end
  end
end