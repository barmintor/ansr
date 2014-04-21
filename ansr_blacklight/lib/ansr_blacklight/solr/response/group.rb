class Ansr::Blacklight::Solr::Response::Group < Ansr::Group

  include Ansr::Blacklight::Solr::Response::PaginationMethods

  attr_reader :response
  
  def initialize group_key, model, group, response
    super(group_key, model, group)
    @response = response
  end

  def doclist
    group[:doclist]
  end

  # short cut to response['numFound']
  def total
    doclist[:numFound].to_s.to_i
  end
    
  def start
    doclist[:start].to_s.to_i
  end

  def docs
    doclist[:docs].map {|doc| model.new(doc)} #TODO do we need to have the solrResponse in the item? 
  end

  def field
    response.group_field
  end
end