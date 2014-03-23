module Ansr::Arel::Visitors
  class Context
    attr_reader :attribute
    def initialize(attribute)
      @attribute = attribute
    end
  end

  %w(Filter From).each do |name|
    const_set(name, Class.new(Context))
  end
end
