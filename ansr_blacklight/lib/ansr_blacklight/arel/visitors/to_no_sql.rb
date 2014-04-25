module Ansr::Blacklight::Arel::Visitors
  class ToNoSql < Ansr::Arel::Visitors::ToNoSql

    def initialize(table, http_method=:get)
      super(table)
    end

    def query_builder()
      Ansr::Blacklight::Arel::Visitors::QueryBuilder.new(table)
    end

  end

end