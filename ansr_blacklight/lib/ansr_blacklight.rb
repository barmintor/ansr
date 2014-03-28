require 'active_support'
module Ansr::Blacklight
  extend ActiveSupport::Autoload
  autoload :SolrProjectionMethods, 'ansr_blacklight/relation/solr_projection_methods'
  require 'ansr_blacklight/solr_request'
  require 'ansr_blacklight/arel'
  require 'ansr_blacklight/connection_adapters/no_sql_adapter'
  require 'ansr_blacklight/relation'
  require 'ansr_blacklight/model/querying'
  require 'ansr_blacklight/base'
end