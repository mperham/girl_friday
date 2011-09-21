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
    queue.shutdown
  end

  def test_should_process_immediately_with_callback
    queue = GirlFriday::WorkQueue.new('now') do |msg|
      msg[:start] + 1
    end
    assert_equal 43, queue.push(:start => 41) { |r| r + 1 }
    queue.shutdown
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
    queue.shutdown
  end
end
