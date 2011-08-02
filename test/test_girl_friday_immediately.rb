require 'helper'

class TestGirlFridayImmediately < MiniTest::Unit::TestCase

  def setup
    GirlFriday::WorkQueue.immediate!
  end

  def teardown
    GirlFriday::WorkQueue.queue!
  end

  def test_should_process_immediately
    queue = GirlFriday::WorkQueue.new('now') do |msg|
      msg[:start] + 1
    end
    assert_equal 42, queue.push(:start => 41)
    assert_equal 42, queue << { :start => 41 }
  end

  def test_should_process_immediately_with_callback
    queue = GirlFriday::WorkQueue.new('now') do |msg|
      msg[:start] + 1
    end
    assert_equal 43, queue.push(:start => 41) { |r| r + 1 }
  end

  def test_should_process_style_idempotently
    queue = GirlFriday::WorkQueue.new('now') do |msg|
      msg[:start] + 1
    end

    5.times { GirlFriday::WorkQueue.queue! }
    5.times { GirlFriday::WorkQueue.immediate! }
    assert_equal 2, queue.push(:start => 1)
    assert_equal 2, queue << {:start => 1}

    10.times do |i|
      if i.odd?
        GirlFriday::WorkQueue.queue!
      else
        GirlFriday::WorkQueue.immediate!
      end
    end
    GirlFriday::WorkQueue.immediate!
    assert_equal 3, queue.push(:start => 2)
    assert_equal 3, queue << {:start => 2}
  end

  def test_should_process_immediately_when_rails_dev
    # remove WorkQueue definitions first, since #push_async is defined
    # as the class definition is executed, and Rails constant is not defined yet
    [:Queue, :WorkQueue].each {|c| GirlFriday.send(:remove_const, c)}

    # now top-level Rails constant will exist
    Object.send(:include, RailsEnvironment)

    # re-load class now that Rails constant is defined
    $".delete_if {|f| f =~ %r{work_queue.rb}}
    require 'girl_friday/work_queue'

    # verify that we process immediately
    queue = GirlFriday::WorkQueue.new('now') do |msg|
      msg[:start] + 1
    end
    assert_equal 4, queue.push(:start => 3)
    assert_equal 4, queue << {:start => 3}
  end
end

module RailsEnvironment
  class Rails
    def self.method_missing(m, *args, &block)
      # swallow every call and return self so that WorkQueue
      # thinks Rails dev environment is loaded
      self
    end
  end
end