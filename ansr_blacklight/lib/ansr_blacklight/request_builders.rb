module Ansr::Blacklight
  ##
  # This module contains methods that transform user parameters into parameters that are sent
  # as a request to Solr when RequestBuilders#solr_search_params is called.
  #
  module RequestBuilders
    extend ActiveSupport::Concern
    # A helper method used for generating solr LocalParams, put quotes
    # around the term unless it's a bare-word. Escape internal quotes
    # if needed. 
    def solr_param_quote(val, options = {})
      options[:quote] ||= '"'
      unless val =~ /^[a-zA-Z0-9$_\-\^]+$/
        val = options[:quote] +
          # Yes, we need crazy escaping here, to deal with regexp esc too!
          val.gsub("'", "\\\\\'").gsub('"', "\\\\\"") + 
          options[:quote]
      end
      return val
    end
    
    ##
    # Take the user-entered query, and put it in the solr params, 
    # including config's "search field" params for current search field. 
    # also include setting spellcheck.q. 
    def add_query_to_solr(search_field, value)
      ###
      # Merge in search field configured values, if present, over-writing general
      # defaults
      ###
      
      if (::Arel::Nodes::As === search_field)     
        solr_request[:qt] = search_field.right.to_s
        search_field = search_field.left
      end
      
      ##
      # Create Solr 'q' including the user-entered q, prefixed by any
      # solr LocalParams in config, using solr LocalParams syntax. 
      # http://wiki.apache.org/solr/LocalParams
      ##         
      if (Ansr::Arel::ConfiguredField === search_field && !search_field.config.empty?)
        local_params = search_field.config.collect do |key, val|
          key.to_s + "=" + solr_param_quote(val, :quote => "'")
        end.join(" ")
        solr_request[:q] = "{!#{local_params}}#{value}"
      else
        solr_request[:q] = value if value
      end

      ##
      # Set Solr spellcheck.q to be original user-entered query, without
      # our local params, otherwise it'll try and spellcheck the local
      # params! Unless spellcheck.q has already been set by someone,
      # respect that.
      #
      # TODO: Change calling code to expect this as a symbol instead of
      # a string, for consistency? :'spellcheck.q' is a symbol. Right now
      # rspec tests for a string, and can't tell if other code may
      # insist on a string. 
      solr_request["spellcheck.q"] = solr_request[:q] unless solr_request["spellcheck.q"]
    end

    ##
    # Add any existing facet limits, stored in app-level HTTP query
    # as :f, to solr as appropriate :fq query. 
    def add_facet_fq_to_solr(solr_request, user_params)   

      # convert a String value into an Array
      if solr_request[:fq].is_a? String
        solr_request[:fq] = [solr_request[:fq]]
      end

      # :fq, map from :f. 
      if ( user_params[:f])
        f_request_params = user_params[:f] 
        
        f_request_params.each_pair do |facet_field, value_list|
          Array(value_list).each do |value|
            solr_request.append_filter_query facet_value_to_fq_string(facet_field, value, user_params[:opts])
          end              
        end      
      end
    end
    
    def with_ex_local_param(ex, value)
      if ex
        "{!ex=#{ex}}#{value}"
      else
        value
      end
    end

    private

    ##
    # Convert a facet/value pair into a solr fq parameter
    def facet_value_to_fq_string(facet_field, value, facet_opts=nil)
      facet_field = table[facet_field]
      facet_config = (Ansr::Arel::ConfiguredField === facet_field)
      facet_default = (::Arel.star == facet_field)
      local_params = []
      local_params << "tag=#{facet_field.tag}" if facet_config and facet_field.tag

      prefix = ""
      prefix = "{!#{local_params.join(" ")}}" unless local_params.empty?

      fq = case
        when facet_default
          ""
        when (facet_config and facet_field.query)
          facet_field.query[value][:fq]
        when (facet_config and facet_field.date),
             (value.is_a?(TrueClass) or value.is_a?(FalseClass) or value == 'true' or value == 'false'),
             (value.is_a?(Integer) or (value.to_i.to_s == value if value.respond_to? :to_i)),
             (value.is_a?(Float) or (value.to_f.to_s == value if value.respond_to? :to_f))
             (value.is_a?(DateTime) or value.is_a?(Date) or value.is_a?(Time))
          "#{prefix}#{facet_field.name}:#{value}"
        when value.is_a?(Range)
          "#{prefix}#{facet_field.name}:[#{value.first} TO #{value.last}]"
        else
          "{!raw f=#{facet_field.name}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
      end


    end
  end
end