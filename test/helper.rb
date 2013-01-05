puts RUBY_DESCRIPTION

at_exit do
  # queue.shutdown is async so sleep a little to minimize
  # race conditions between us and other threads
  # that haven't yet been GC'd.
  sleep 0.1
  if Thread.list.size > 1
    Thread.list.each do |thread|
      next if thread.status == 'run'
      puts "WARNING: lingering threads found.  All threads should be shutdown and garbage collected."
      puts "This is normal if a test failed so a queue did not get shutdown."
      p [thread, thread[:label]]
    end
  end
end

unless ENV['CI']
  require 'simplecov'
  SimpleCov.start do
    add_filter "/actor.rb"
  end
end

require 'rubygems'
require 'minitest/spec'
require 'minitest/autorun'
require 'connection_pool'
require 'girl_friday'
require 'flexmock/minitest'

class MiniTest::Unit::TestCase

  def async_test(time=0.5)
    q = ConnectionPool::TimedStack.new
    yield Proc.new { q << nil }
    q.pop(time)
  ensure
    count = GirlFriday.shutdown!(1)
    puts "Unable to shutdown queue (#{count})" if count != 0
  end

end

module Faker
  def initialize
    @number_of_calls = 0
  end

  def number_of_calls
    @number_of_calls
  end


  def count(*args,&blk)
    @number_of_calls += 1
  end
end
