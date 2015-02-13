require 'ansr'
require 'rsolr'
module Ansr::Blacklight
  extend ActiveSupport::Autoload
  autoload :SolrProjectionMethods, 'ansr_blacklight/relation/solr_projection_methods'
  require 'ansr_blacklight/solr'
  require 'ansr_blacklight/request_builders'
  require 'ansr_blacklight/arel'
  require 'ansr_blacklight/connection_adapters/no_sql_adapter'
  require 'ansr_blacklight/relation'
  require 'ansr_blacklight/repository'
  require 'ansr_blacklight/model/querying'
  require 'ansr_blacklight/base'

    def self.solr_file
    "#{::Rails.root.to_s}/config/solr.yml"
  end
  
  def self.solr
    @solr ||=  RSolr.connect(Ansr::Blacklight.solr_config)
  end

  def self.solr_config
    @solr_config ||= begin
        raise "The #{::Rails.env} environment settings were not found in the solr.yml config" unless solr_yml[::Rails.env]
        solr_yml[::Rails.env].symbolize_keys
      end
  end

  def self.solr_yml
    require 'erb'
    require 'yaml'

    return @solr_yml if @solr_yml
    unless File.exists?(solr_file)
      raise "You are missing a solr configuration file: #{solr_file}. Have you run \"rails generate blacklight:install\"?"  
    end

    begin
      @solr_erb = ERB.new(IO.read(solr_file)).result(binding)
    rescue Exception => e
      raise("solr.yml was found, but could not be parsed with ERB. \n#{$!.inspect}")
    end

    begin
      @solr_yml = YAML::load(@solr_erb)
    rescue StandardError => e
      raise("solr.yml was found, but could not be parsed.\n")
    end

    if @solr_yml.nil? || !@solr_yml.is_a?(Hash)
      raise("solr.yml was found, but was blank or malformed.\n")
    end

    return @solr_yml
  end

end