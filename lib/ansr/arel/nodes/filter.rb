module Ansr::Arel::Nodes
  class UnaryProperties < ::Arel::Nodes::Node
    attr_reader :expr, :opts

    def initialize(expr, opts={})
      @expr = expr
      @opts = opts
      @opts[:select] = true unless @opts.has_key? :select
    end

    def select(*val)
      puts "#{expr}.select(#{val.inspect})"
      @opts[:select] = val.first.to_s.downcase != 'false' if val.first
      @opts[:select]
    end

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

  class Filter < UnaryProperties; end
  class Highlight < UnaryProperties; end
  class Spellcheck < UnaryProperties; end
end