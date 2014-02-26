module Adpla
  module Configurable
    def config(yaml=nil)
      yaml ? @config ||= begin
        y = begin
          case yaml
          when String
            File.open(yaml) {|blob| YAML.load(blob)}
          else
            yaml
          end
        end
        raise "DPLA clients must be configured with an API key" unless y[:api_key]
        y
      end : @config
    end
  end
  
  require 'adpla/api'
  require 'adpla/arel'
  require 'adpla/model'
  require 'adpla/relation'
  require 'adpla/version'
end