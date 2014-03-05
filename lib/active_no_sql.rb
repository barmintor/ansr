require 'active_support'
module ActiveNoSql
  extend ActiveSupport::Autoload
  eager_autoload do
    autoload :Configurable
    autoload :BigTable
    autoload :Base
    autoload :Model
    autoload :Sanitization
    autoload :Relation
    autoload_under 'relation' do
      autoload :ArelMethods
      autoload :QueryMethods
    end
  end
end