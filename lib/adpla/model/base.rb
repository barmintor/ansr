require 'active_no_sql'
module Adpla
  module Model
    class Base < ActiveNoSql::Base
  	  extend Querying

  	  def initialize doc
  	  	@doc = doc
  	  end

  	  def [](key)
  	  	@doc[key]
  	  end

  	  def readonly!
  	  end

      def self.model
        self
      end

      def self.table
        @big_table ||= Adpla::Arel::BigTable.new(model(), nil, {:config => self.config})
      end

      def self.table=(table)
        @big_table = table
      end

      def self.engine
        @engine ||= begin
          e = Adpla::Arel::Engine.new
          e.config(self.config)
          e
        end
        @engine
      end

      def self.api
        @api ||= begin
          a = (config[:api] || Adpla::Api).new
          a.config(self.config)
          a
        end
      end

      def self.api=(api)
        @api = api
      end


      def self.connection_handler
        @connection_handler ||= ConnectionHandler.new
      end

      def self.connection_handler=(handler)
        @connection_handler = handler
      end

  	  def self.build_default_scope
  	  	self.all
  	  end

      # need to find a way to accommodate the prefixed fields and filters
      def self.sanitize_sql(args)
        args
      end

      def self.arel_engine
        nil
      end
    end
  end
end