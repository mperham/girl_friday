$testing = true

# require 'simplecov'
# SimpleCov.start do
#   add_filter "/actor.rb"
# end

# rbx is 1.8-mode for another month...
require 'rubygems'
require 'minitest/autorun'
require 'connection_pool'
require 'girl_friday'
require 'flexmock/minitest'

puts RUBY_DESCRIPTION

class MiniTest::Unit::TestCase

  def async_test(time=0.5)
    q = TimedQueue.new
    yield Proc.new { q << nil }
    q.timed_pop(time)
  end

end
