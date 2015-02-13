module Ansr::Arel
  class ConfiguredField < ::Arel::Attributes::Attribute
    attr_reader :config
    def initialize(relation, name, config={})
      super(relation, name)
      @config = {}.merge(config)
    end
    def query
      @config[:query]
    end
    def local
      @config[:local]
    end
    def method_missing(method, *args)
      @config[method] = args if args.first
      @config[method]
    end
  end
end