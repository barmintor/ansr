$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app/models'))
require 'rails'
require 'adpla'
require 'item'
class Logger
  def info(msg)
    puts msg
  end
  alias :warn :info
  alias :error :info
  alias :debug :info
end

puts Item.table.inspect