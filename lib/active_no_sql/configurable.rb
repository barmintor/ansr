module ActiveNoSql
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

    alias_method :configure, :config

  end
end