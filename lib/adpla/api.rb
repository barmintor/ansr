module Adpla
  class Api

    def config(yaml={})
      @config ||= begin
        y = (yaml.is_a? String) ? YAML.load(yaml) : yaml
        raise "DPLA clients must be configured with an API key" unless y[:api_key]
        y  
      end
    end

    def api_key
      config[:api_key]
    end

    def url
      config[:url] || 'http://api.dp.la/v2/'
    end

    def path_for base, options = nil
      return base unless options.is_a? Hash
      options = {:api_key=>api_key}.merge(options)
      options[:facets] = options[:facets].join(',') if options[:facets].is_a? Array
      "#{base}" + (("?#{options.map { |key, value|  "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"}.join("&")  }" if options and not options.empty?) || '')
    end

    def client
      @client ||= RestClient::Resource.new(self.url)
    end

    def items(options = {})
      client[path_for('items', options)].get
    end

    def item(id)
      client[path_for("items/#{id}")].get
    end

    def collections(options = {})
      client[path_for('collections', options)].get
    end

    def collection(id)
      client[path_for("collections/#{id}")].get
    end
  end
end