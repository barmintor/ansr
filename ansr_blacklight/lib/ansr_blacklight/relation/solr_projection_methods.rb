module Ansr::Blacklight
  module SolrProjectionMethods
    def defType_value
      @values[:defType]
    end

    def defType_value=(value)
      raise ImmutableRelation if @loaded
      @values[:defType] = value
    end

    def defType(value)
      spawn.defType!(value)
    end

    def defType!(value)
      self.defType_value= value
      self
    end

    def defType_unscoping
    end

    def wt_value
      @values[:wt]
    end

    def wt_value=(value)
      raise ImmutableRelation if @loaded
      @values[:wt] = value
    end

    def wt(value)
      spawn.wt!(value)
    end

    def wt!(value)
      self.wt_value= (value)
      self
    end

    def wt_unscoping
    end

    # omitHeader

    # timeAllowed

    # debug (true, :timing, :query, :results)

    # explainOther

    # debug.explain.structured
  end
end