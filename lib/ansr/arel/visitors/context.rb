module Ansr::Arel::Visitors
  class Context
    attr_reader :attribute
    def initialize(attribute)
      @attribute = attribute
    end
  end

  %W(Facet Filter From Order).each do |name|
    const_set(name, Class.new(Context))
  end
end
