module Ansr
  module Configurable
    def config
      @config ||= {}
      if block_given?
        yield @config
      end
      @config
    end

    alias_method :configure, :config

  end
end