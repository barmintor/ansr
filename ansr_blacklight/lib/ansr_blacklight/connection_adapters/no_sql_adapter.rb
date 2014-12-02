module Ansr::Blacklight::ConnectionAdapters
  class NoSqlAdapter < Ansr::ConnectionAdapters::NoSqlAdapter

    def self.connection_for(klass)
      Ansr::Blacklight.solr
    end

    def initialize(klass, logger = nil, pool = nil) #:nodoc:
      super(klass, klass.solr, logger, pool)
      # the RSolr class has one query method, with the name of the selector the first parm?
      @method = :send_and_receive
      @http_method = klass.method
      @visitor = Ansr::Blacklight::Arel::Visitors::ToNoSql.new(@table)
    end

    # RSolr
    def raw_connection
        @connection
    end

    def adapter_name
        'Solr'
    end

    def to_sql(*args)
      to_nosql(*args)
    end

    def execute(query, name='ANSR-SOLR')
      query = query.dup
      # TODO: execution context to assign :post to params[:method]
      params = {params: query, method: @http_method}
      params[:data] = params.delete(:params) if @http_method == :post
      raw_response = @connection.send(@method, query.path || 'select', params)
      Ansr::Blacklight::Solr::Response.new(raw_response, raw_response['params'])
    end

  end
end