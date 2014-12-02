module Ansr::Arel::Visitors
  class Context
    attr_reader :attribute
    def initialize(attribute)
      @attribute = attribute
    end
  end

  # create some thin subclasses in this module
  %W(Facet Filter From Order ProjectionTraits).each do |name|
    const_set(name, Class.new(Context))
  end
end
