# encapsulate a set of a response documents grouped on a field
module Ansr
  class Group
    attr_reader :field, :key, :group, :model
    def initialize(group_key, model, group)
      @field, @key = group_key.first
      @model = model
      @group = group
    end

    # size of the group
    def total
      raise "Group#total must be implemented by subclass"
    end

    # offset in the response
    def start
      raise "Group#start must be implemented by subclass"
    end

    # model instances belonging to this group
    def records
      raise "Group#records must be implemented by subclass"
    end

    # the field from which the key value was selected
    def field
      raise "Group#field must be implemented by subclass"
    end
  end
end