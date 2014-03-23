module Ansr::Arel::Visitors  
  class QueryBuilder  < Arel::Visitors::Visitor
    attr_reader :table
    def initialize(table)
      @table = table
    end

    def visit(object, attribute)
      super
    end

    def visit_Ansr_Arel_BigTable(object, attribute)
      from(object) if From === attribute
    end

    def visit_Arel_Nodes_SelectCore(object, attribute)
      visit(object.froms, From.new(attribute)) if object.froms
      object.projections.each { |x| visit(x, attribute) }
      object.wheres.each { |x| visit(x, attribute) }
      object.groups.each {|x| visit(x, attribute) if x}
      self
    end

    def visit_Symbol o, a
      Filter === a ? filter_field(o) : field(o)
    end

    def visit_String o, a
      case a
      when From
        from(o)
      when Filter
        filter_field(o)
      else
        raise "visited String \"#{o}\" with #{a.to_s}"
      end
    end

    def visit_Array o, a
      o.map { |x| visit x, a }
    end


    def visit_Arel_Nodes_And(object, attribute)
      visit(object.children, attribute)
    end

    def field_key_from_node(node)
      table.model.field_name(node)
    end

    # determines whether multiple values should accumulate or overwrite in merges
    def multiple?(field_key)
      false
    end

    private
    def from(*args)
    end
  end
end