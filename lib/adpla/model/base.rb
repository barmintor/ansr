module Adpla
  module Model
    class Base
  	  extend Adpla::Model::Methods
  	  extend Adpla::Model::Querying

  	  def initialize doc
  	  	@doc = doc
  	  end

  	  def [](key)
  	  	@doc[key]
  	  end

  	  def readonly!
  	  end

  	  def self.build_default_scope
  	  	self.all
  	  end
    end
  end
end