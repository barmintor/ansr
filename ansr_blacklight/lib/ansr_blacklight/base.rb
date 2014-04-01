module Ansr::Blacklight
  class Base < Ansr::Base
    #include Blacklight::Configurable
    include Ansr::Blacklight::Model::Querying

    self.abstract_class = true

  end
end