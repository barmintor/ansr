module Ansr
  module ArelMethods
    # Returns the Arel object associated with the relation.
    # duplicated to respect access control
    def arel # :nodoc:
      @arel ||= build_arel
    end

    def arel_table
      model().table
    end

  end
end