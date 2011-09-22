$testing = true
puts RUBY_DESCRIPTION

at_exit do
  if Thread.list.size > 1
    Thread.list.each do |thread|
      next if thread.status == 'run'
      puts "WARNING: lingering threads found.  All threads should be shutdown and garbage collected."
      p [thread, thread['name']]
#      puts thread.backtrace.join("\n")
    end
  end
end

# require 'simplecov'
# SimpleCov.start do
#   add_filter "/actor.rb"
# end

require 'rubygems'
require 'minitest/spec'
require 'minitest/autorun'
require 'connection_pool'
require 'girl_friday'
require 'flexmock/minitest'

class MiniTest::Unit::TestCase

  def async_test(time=0.5)
    q = TimedQueue.new
    yield Proc.new { q << nil }
    q.timed_pop(time)
  end

end
