class Collection
  extend Adpla::Model::Methods

  def initialize doc
  	@doc = doc
  end

  def [](key)
  	@doc[key]
  end

  def readonly!
  end

end