module ActiveNoSql
  class Base < ActiveRecord::Base
    extend ActiveNoSql::Model::Methods
    extend ActiveNoSql::Configurable
    extend ActiveNoSql::QueryMethods
    extend ActiveNoSql::ArelMethods

    def self.table
      raise 'Implementing classes must provide a BigTable reader'
    end

    def self.table=(table)
      raise 'Implementing classes must provide a BigTable writer'
    end

    def self.engine
      raise 'Implementing classes must provide an Engine factory'
    end

    def self.spawn
      ActiveNoSql::Relation.new(self, self.table)
    end

    def self.inherited(subclass)
      # a hack for sanitize sql overrides to work, and some others where @klass used in place of klass()
      self.model = subclass
    end

  end
end