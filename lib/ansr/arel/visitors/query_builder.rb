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
      visit object.name, attribute if Ansr::Arel::Visitors::From === attribute
      @table = object if Ansr::Arel::BigTable === object and Ansr::Arel::Visitors::From === attribute
    end

    def visit_Arel_Nodes_SelectCore(object, attribute)
      visit(object.froms, From.new(attribute)) if object.froms
      object.projections.each { |x| visit(x, attribute) }
      object.wheres.each { |x| visit(x, attribute) }
      object.groups.each {|x| visit(x, attribute) if x}
      self
    end

    def visit_Symbol o, a
      visit o.to_s, a
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

  end
end