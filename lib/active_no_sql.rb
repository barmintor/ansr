require 'active_support'
module ActiveNoSql
  extend ActiveSupport::Autoload
  eager_autoload do
    autoload :Configurable
    autoload :Base
    autoload :Model
    autoload :Relation
    autoload_under 'relation' do
      autoload :ArelMethods
      autoload :QueryMethods
    end
  end
end