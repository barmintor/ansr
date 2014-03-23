require 'arel'
module Ansr::Arel
  class IntersectManager < ::Arel::TreeManager

    def initialize(engine, ast)
      super(engine)
      @ast = ast
      @filter_ctx = @ast.right.cores.last
      @unfiltered_ctx = @ast.left.cores.last
    end

    def projections
      @unfiltered_ctx.projections
    end

    # this needs to be refactored towards maintaining separation longer to support BL's fq
    def constraints
      (@unfiltered_ctx.wheres + @filter_ctx.wheres).uniq
    end

    def orders
      ast.left.orders
    end

    def offset
      ast.left.limit && ast.left.limit.expr
    end

    def take
      ast.left.take
      ast.left.take && ast.left.take.expr
    end
  end
end