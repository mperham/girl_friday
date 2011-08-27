require 'rubygems' # for rbx
here = File.dirname(__FILE__)
$LOAD_PATH.unshift File.expand_path(here + '/../../lib')
$LOAD_PATH.unshift here
require 'girl_friday'
require 'mongo_persistence'

class Foo
  def initialize(msg)
    puts msg.inspect
  end
end

PUTS_QUEUE = GirlFriday::WorkQueue.new(:puts_mongo, :store => GirlFriday::Store::Mongo) do |msg|
  Foo.new(msg)
end

1.upto(100) do |i|
  PUTS_QUEUE << { :what => i }
end

sleep 2
