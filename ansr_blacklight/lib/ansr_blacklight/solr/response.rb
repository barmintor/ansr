## copied directly from Blacklight::SolrResponse
class Ansr::Blacklight::Solr::Response < HashWithIndifferentAccess

  require  'ansr_blacklight/solr/response/pagination_methods'

  autoload :Spelling, 'ansr_blacklight/solr/response/spelling'
  autoload :MoreLikeThis, 'ansr_blacklight/solr/response/more_like_this'
  autoload :GroupResponse, 'ansr_blacklight/solr/response/group_response'
  autoload :Group, 'ansr_blacklight/solr/response/group'

  include Ansr::Blacklight::Solr::Response::PaginationMethods

  attr_reader :request_params
  def initialize(data, request_params)
    super(data)
    @request_params = request_params
    extend Spelling
    extend Ansr::Facets
    extend InternalResponse
    extend MoreLikeThis
  end

  def header
    self['responseHeader']
  end
  
  def update(other_hash) 
    other_hash.each_pair { |key, value| self[key] = value } 
    self 
  end 

  def params
      (header and header['params']) ? header['params'] : request_params
  end

  def rows
      params[:rows].to_i
  end

  def docs
    @docs ||= begin
      response['docs'] || []
    end
  end

  def spelling
    self['spelling']
  end

  def grouped(model)
    @groups ||= self["grouped"].map do |field, group|
      # grouped responses can either be grouped by:
      #   - field, where this key is the field name, and there will be a list
      #        of documents grouped by field value, or:
      #   - function, where the key is the function, and the documents will be
      #        further grouped by function value, or:
      #   - query, where the key is the query, and the matching documents will be
      #        in the doclist on THIS object
      if group["groups"] # field or function
        GroupResponse.new field, model, group, self
      else # query
        Group.new({field => field}, model, group, self)
      end
    end
  end

  def group key, model
    grouped(model).select { |x| x.key == key }.first
  end

  def grouped?
    self.has_key? "grouped"
  end

  module InternalResponse
    def response
      self[:response] || {}
    end
    
    # short cut to response['numFound']
    def total
      response[:numFound].to_s.to_i
    end
    
    def start
      response[:start].to_s.to_i
    end

    def empty?
      total == 0
    end
    
  end
end
