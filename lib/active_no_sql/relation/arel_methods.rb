module ActiveNoSql
  module ArelMethods
    # Returns the Arel object associated with the relation.
    # duplicated to respect access control
    def arel # :nodoc:
      @arel ||= build_arel
    end

    def build_arel
      arel = super
      build_filter(arel, filter_values.uniq)
      #collapse_wheres(arel, (filter_values - ['']).uniq)
      arel
    end

    def arel_table
      model.table
    end

  end
end