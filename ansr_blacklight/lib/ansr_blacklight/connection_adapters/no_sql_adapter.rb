module Ansr::Blacklight::ConnectionAdapters
  class NoSqlAdapter < Ansr::ConnectionAdapters::NoSqlAdapter

    attr_accessor :blacklight_config

    def self.connection_for(klass)
      klass.solr
    end

    def initialize(klass, logger = nil, pool = nil) #:nodoc:
      super(klass, klass.solr, logger, pool)
      # the RSolr class has one query method, with the name of the selector the first parm?
      @method = :send_and_receive
      @blacklight_config = klass.blacklight_config
      @visitor = Ansr::Blacklight::Arel::Visitors::ToNoSql.new(@table, @blacklight_config)
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
      query[:qt] = blacklight_config.qt unless query[:qt] or !blacklight_config.qt
      params = {params: query, method: blacklight_config.http_method || :get}
      params[:data] = params.delete(:params) if params[:method] == :post
      raw_response = eval(@connection.send(@method, query[:query_handler], params))
      Blacklight::SolrResponse.new(raw_response, raw_response['params'])
    end

    # how can we determine the names of the query handlers (and corresponding "table")?
    def table_exists?(table_name)
      true
    end

  end
end