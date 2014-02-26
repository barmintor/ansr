module Adpla
  module Model
    module Methods
      include Adpla::Configurable

      alias_method :configure, :"config"

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
    end
  end
end