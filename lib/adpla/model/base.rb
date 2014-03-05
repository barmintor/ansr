require 'active_no_sql'
module Adpla
  module Model
    class Base < ActiveNoSql::Base
      self.abstract_class = true

  	  include Querying


    end
  end
end