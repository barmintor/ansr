class Ansr::Blacklight::Solr::Response::GroupResponse

  include Ansr::Blacklight::Solr::Response::PaginationMethods

  attr_reader :key, :model, :group, :response

  def initialize key, model, group, response
    @key = key
    @model = model
    @group = group
    @response = response
  end

  alias_method :group_field, :key

  def groups
    @groups ||= group["groups"].map do |g|
      Ansr::Blacklight::Solr::Response::Group.new({key => g[:groupValue]}, model, g, self)
    end
  end

  def group_limit
    params.fetch(:'group.limit', 1).to_s.to_i
  end

  def total
    # ngroups is only available in Solr 4.1+
    # fall back on the number of facet items for that field?
    (group["ngroups"] || (response.facet_by_field_name(key) || []).length).to_s.to_i
  end
    
  def start
    params[:start].to_s.to_i
  end

  def method_missing meth, *args, &block

    if response.respond_to? meth
      response.send(meth, *args, &block)
    else
      super
    end

  end

  def respond_to? meth
    response.respond_to?(meth) || super
  end

end