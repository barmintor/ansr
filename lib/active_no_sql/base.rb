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
      table().engine
    end

    def self.spawn
      ActiveNoSql::Relation.new(self)
    end

    def self.inherited(subclass)
      # a hack for sanitize sql overrides to work, and some others where @klass used in place of klass()
      subclass.instance_variable_set(:"@klass", subclass)
    end

  end
end