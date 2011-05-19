require 'helper'

class TestGirlFridayRunner < MiniTest::Unit::TestCase

  class TestErrorHandler
    include MiniTest::Assertions
  end

  def test_honor_size_option
    size = 42
    
    runner = GirlFriday::Runner.spawn :sized_queue, :size => size
    assert_equal size, runner.status[:pool_size]
  end
  
  def test_shutdown
    runner = GirlFriday::Runner.spawn :soon_to_be_dead_queue
    runner.shutdown
    
    begin
      runner.status
    rescue => ex
    end
    
    assert_equal Celluloid::DeadActorError, ex.class
  end
  
  def test_does_work
    queue = Queue.new
    
    runner = GirlFriday::Runner.spawn(:test) { |args| queue << args[:obj] }
    assert_equal 0, runner.status[:total_processed]
    
    test_object = 42
    runner.push :obj => test_object
    
    assert_equal test_object, queue.pop
  end
  
  def test_tracks_total_processed
    queue = Queue.new
    
    runner = GirlFriday::Runner.spawn(:test) { |args| queue << args[:obj] }
    assert_equal 0, runner.status[:total_processed]
    
    runner.push :obj => :done
    queue.pop 
    
    assert_equal 1, runner.status[:total_processed]
  end
  
  def test_runs_callbacks
    queue = Queue.new
    runner = GirlFriday::Runner.spawn(:test) { |args| args[:n] + 40 }
    runner.push(:n => 2) { |result| queue << result }
    
    assert_equal 42, queue.pop
  end
  
  ErrorQueue = Queue.new
  
  class TestErrorHandler
    def handle(ex)
      ErrorQueue << ex
    end
  end
  
  class RunnerTestError < StandardError; end
  
  def test_handles_errors
    example_error = RunnerTestError.new "this is a test of the emergency error handling system"
    
    runner = GirlFriday::Runner.spawn :test, :error_handler => TestErrorHandler do
      raise example_error
    end
    
    runner.push
    assert_equal example_error, ErrorQueue.pop
  end
end