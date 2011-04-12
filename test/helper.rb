$testing = true
require 'test/unit'
require 'timed_queue'
require 'girl_friday'

puts RUBY_DESCRIPTION

class Test::Unit::TestCase

  def async_test(time=0.5)
    q = TimedQueue.new
    yield Proc.new { q << nil }
    q.timed_pop(time)
  end

end