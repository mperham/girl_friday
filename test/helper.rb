$testing = true
unless defined? $queue_work
  $queue_work = true
end
# require 'simplecov'
# SimpleCov.start do
#   add_filter "/actor.rb"
# end

# rbx is 1.8-mode for another month...
require 'rubygems'
require 'minitest/autorun'
require 'timed_queue'
require 'girl_friday'

puts RUBY_DESCRIPTION

class MiniTest::Unit::TestCase

  def async_test(time=0.5)
    q = TimedQueue.new
    yield Proc.new { q << nil }
    q.timed_pop(time)
  end

end
