module Ansr::Blacklight::ConnectionAdapters
  class NoSqlAdapter < Ansr::ConnectionAdapters::NoSqlAdapter

    def self.connection_for(klass)
      Ansr::Blacklight.solr
    end

    def initialize(klass, logger = nil, pool = nil) #:nodoc:
      super(klass, klass.solr, logger, pool)
      # the RSolr class has one query method, with the name of the selector the first parm?
      @method = :send_and_receive
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
      params = {params: query, method: :get}
      params[:data] = params.delete(:params) if params[:method] == :post
      raw_response = eval(@connection.send(@method, query.path, params))
      Ansr::Blacklight::Solr::Response.new(raw_response, raw_response['params'])
    end

    # how can we determine the names of the query handlers (and corresponding "table")?
    def table_exists?(table_name)
      true
    end

  end
end