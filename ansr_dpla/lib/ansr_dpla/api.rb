require 'rest_client'
module Ansr::Dpla
  class Api
    include Ansr::Configurable

    def config &block
      super &block
      raise "DPLA clients must be configured with an API key" unless @config[:api_key]
      @config
    end


    API_PARAM_KEYS = [:api_key, :callback, :facets, :fields, :page, :page_size, :sort_by, :sort_by_pin, :sort_order]

    def initialize(config=nil)
      self.config{|x| x.merge!(config)} if config
    end

    def api_key
      config[:api_key]
    end

    def url
      config[:url] || 'http://api.dp.la/v2/'
    end

    def path_for base, options = nil
      return "#{base}?api_key=#{self.api_key}" unless options.is_a? Hash
      options = {:api_key=>api_key}.merge(options)
      API_PARAM_KEYS.each do |query_key|
        options[query_key] = options[query_key].join(',') if options[query_key].is_a? Array
      end
      (options.keys - API_PARAM_KEYS).each do |query_key|
        options[query_key] = options[query_key].join(' AND ') if options[query_key].is_a? Array
        options[query_key].sub!(/^OR /,'')
        options[query_key].gsub!(/\s+AND\sOR\s+/, ' OR ')
      end
      "#{base}" + (("?#{options.map { |key, value|  "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"}.join("&")  }" if options and not options.empty?) || '')
    end

    def client
      @client ||= RestClient::Resource.new(self.url)
    end

    def items_path(options={})
      path_for('items', options)
    end

    def items(options = {})
      client[items_path(options)].get
    end

    def item_path(id)
      path_for("items/#{id}")
    end

    def item(id)
      client[item_path(id)].get
    end

    def collections_path(options={})
      path_for('collections', options)
    end

    def collections(options = {})
      client[collections_path(options)].get
    end

    def collection_path(id)
      path_for("collections/#{id}")
    end

    def collection(id)
      client[collection_path(id)].get
    end

  end
end