module Ansr::Dpla::Arel::Visitors
  class ToNoSql < Ansr::Arel::Visitors::ToNoSql

    def query_builder(opts = nil)
      Ansr::Dpla::Arel::Visitors::QueryBuilder.new(table, opts)
    end

  end
end