module Ansr::Arel::Nodes
  class ConfiguredUnary < ::Arel::Nodes::Node
    attr_reader :expr, :opts

    def initialize(expr, opts={})
      @expr = expr
      @opts = opts
    end

    def method_missing(method, *args)
      @opts[method] = args if args.first
      @opts[method]
    end

  end

  class Facet < ConfiguredUnary

    def order(*val)
      if val.first
        val = val.first.downcase.to_sym if String === val
        @opts[:order] = val if val == :asc or val == :desc
      end
      @opts[:order]
    end

    def prefix(*val)
      @opts[:prefix] = val.first.to_s if val.first
      @opts[:prefix]
    end

    def limit(*val)
      @opts[:limit] = val.first.to_s if val.first
      @opts[:limit]
    end
  end
  class Filter < ConfiguredUnary; end
  class Highlight < ConfiguredUnary; end
  class ProjectionTraits < ConfiguredUnary; end
  class Spellcheck < ConfiguredUnary; end
end