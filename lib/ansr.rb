require 'active_support'
require 'active_record'
module Ansr
  extend ActiveSupport::Autoload
  eager_autoload do
    autoload :Configuration
    autoload :Configurable
    autoload :ConnectionAdapters
    autoload :DummyAssociations
    autoload :Arel
    autoload :Facets
    autoload :Base
    autoload :Model
    autoload :Sanitization
    autoload :Relation
    autoload :Repository
    autoload :OpenStructWithHashAccess, 'ansr/utils'
    autoload_under 'relation' do
      autoload :Group
      autoload :PredicateBuilder
      autoload :ArelMethods
      autoload :QueryMethods
    end
  end
end