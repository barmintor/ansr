module Adpla
  module Model
    module Methods
      def config=(yaml={})
        yaml = YAML.load(yaml) if yaml.is_a? String
        @config = yaml
      end

      alias_method :configure, :"config="

      def config
        @config ||= {}
      end

      def api
        @api ||= (config[:api] || Adpla::Api).new
      end

      def api=(api)
        @api = api
      end
    end
  end
end