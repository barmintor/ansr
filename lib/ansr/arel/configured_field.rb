module Ansr::Arel
  class ConfiguredField < ::Arel::Attributes::Attribute
  	attr_reader :config
  	def initialize(relation, name, config={})
  		super(relation, name)
  		@config = config
  	end
    def method_missing(method, *args)
      @config[method] = args if args.first
      @config[method]
    end
  end
end