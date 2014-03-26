module Ansr::Blacklight::Arel::Visitors
  class ToNoSql < Ansr::Arel::Visitors::ToNoSql
    attr_reader :blacklight_config
    
	  def initialize(table, blacklight_config)
      super(table)
      @blacklight_config = blacklight_config
    end

    def query_builder(opts = blacklight_config)
      Ansr::Blacklight::Arel::Visitors::QueryBuilder.new(table, opts)
    end

  end

end