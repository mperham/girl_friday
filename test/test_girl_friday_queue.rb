require 'helper'

class TestGirlFridayQueue < MiniTest::Unit::TestCase

  class TestErrorHandler
    include MiniTest::Assertions
  end

  def test_should_process_messages
    async_test do |cb|
      queue = GirlFriday::WorkQueue.new('process') do |msg|
        assert_equal 'foo', msg[:text]
        queue.shutdown do
          cb.call
        end
      end
      queue.push(:text => 'foo')
    end
  end

  def test_should_handle_worker_error
    async_test do |cb|
      queue = nil
      TestErrorHandler.send(:define_method, :handle) do |ex|
        assert_equal 'oops', ex.message
        assert_equal 'RuntimeError', ex.class.name
        queue.shutdown do
          cb.call
        end
      end

      queue = GirlFriday::WorkQueue.new('error', :error_handler => TestErrorHandler) do |msg|
        raise 'oops'
      end
      queue.push(:text => 'foo')
    end
  end

  def test_should_handle_worker_error_with_retry
    async_test do |cb|
      TestErrorHandler.send(:define_method, :handle) do |ex|
      end

      queue = GirlFriday::WorkQueue.new('error', :error_handler => TestErrorHandler, :size => 1) do |msg|
        begin
          raise 'oops' if msg == 1
          queue.shutdown do
            cb.call
          end
        ensure
          queue.push(0)
        end
      end
      queue.push(1)
    end
  end

  def test_should_use_a_default_error_handler_when_none_specified
    async_test do |cb|
      queue = GirlFriday::WorkQueue.new('error') do |msg|
      end
      queue.shutdown do
        cb.call
      end
      queue.push(:text => 'foo') # Redundant

      # Not an ideal method, but I can't see a better way without complex stubbing.
      assert queue.instance_eval { @error_handlers }.length > 0
    end
  end

  def test_should_call_callback_when_complete
    async_test do |cb|
      queue = GirlFriday::WorkQueue.new('callback', :size => 1) do |msg|
        assert_equal 'foo', msg[:text]
        'camel'
      end
      queue.push(:text => 'foo') do |result|
        assert_equal 'camel', result
        queue.shutdown do
          cb.call
        end
      end
    end
  end

  def test_should_provide_status
    mutex = Mutex.new
    total = 200
    count = 0
    incr = Proc.new do
      mutex.synchronize do
        count += 1
      end
    end

    actual = nil
    async_test do |cb|
      queue = GirlFriday::WorkQueue.new('status', :size => 3) do |msg|
        mycount = incr.call
        actual = queue.status if mycount == 100
        queue.shutdown do
          cb.call
        end if mycount == total
      end
      total.times do |idx|
        queue.push(:text => 'foo')
      end
    end

    refute_nil actual
    refute_nil actual['status']
    metrics = actual['status']
    assert metrics[:total_queued] > 0
    assert metrics[:total_queued] <= total
    assert_equal 3, metrics[:pool_size]
    assert_equal 3, metrics[:busy]
    assert_equal 0, metrics[:ready]
    assert(metrics[:backlog] > 0)
    assert(metrics[:total_processed] > 0)
  end

  def test_should_persist_with_redis_connection_pool
    begin
      require 'redis'
      require 'connection_pool'
      pool = ConnectionPool.new(:size => 5, :timeout => 2){ Redis.new }
      pool.with_connection {|redis| redis.flushdb }
    rescue LoadError
      return puts "Skipping redis test, 'redis' gem not found: #{$!.message}"
    rescue Errno::ECONNREFUSED
      return puts 'Skipping redis test, not running locally'
    end

    mutex = Mutex.new
    total = 100
    count = 0
    incr = Proc.new do
      mutex.synchronize do
        count += 1
      end
    end

    async_test(2.0) do |cb|
      queue = GirlFriday::WorkQueue.new('redis-pool', :size => 2, :store => GirlFriday::Store::Redis, :store_config => { :pool => pool }) do |msg|
        incr.call
        queue.shutdown do
          cb.call
        end if count == total
      end
      total.times do
        queue.push(:text => 'foo')
      end
      refute_nil queue.status['redis-pool'][:backlog]
    end
  end

  def test_should_raise_if_no_store_config_passed_in_for_redis_backend
    assert_raises(ArgumentError) do
      GirlFriday::WorkQueue.new('raise-test', :store => GirlFriday::Store::Redis) do |msg|
        # doing work
      end
    end
  end

  def test_should_allow_graceful_shutdown
    mutex = Mutex.new
    total = 100
    count = 0
    incr = Proc.new do
      mutex.synchronize do
        count += 1
      end
    end

    async_test do |cb|
      queue = GirlFriday::WorkQueue.new('shutdown', :size => 2) do |msg|
        incr.call
        cb.call if count == total
      end
      total.times do
        queue.push(:text => 'foo')
      end

      assert_equal 1, GirlFriday.queues.size
      count = GirlFriday.shutdown!
      assert_equal 0, count
      cb.call
    end
  end

  def test_should_allow_in_progress_work_to_finish
    mutex = Mutex.new
    total = 8
    count = 0
    incr = Proc.new do
      mutex.synchronize do
        count += 1
      end
    end

    async_test(10) do |cb|
      queue = GirlFriday::WorkQueue.new('finish', :size => 10) do |msg|
        sleep 1
        incr.call
      end
      total.times do
        queue.push(:text => 'foo')
      end

      GirlFriday.shutdown!
      assert_equal total, queue.instance_variable_get("@total_processed")
      assert_equal total, count
      cb.call
    end
  end

  def test_should_create_workers_lazily
    async_test do |cb|
      queue = GirlFriday::Queue.new('lazy', :size => 2) do |msg|
        assert_equal 1, queue.instance_variable_get(:@ready_workers).size
        queue.shutdown do
          cb.call
        end
      end
      assert queue.instance_variable_defined?(:@ready_workers)
      assert_nil queue.instance_variable_get(:@ready_workers)
      # don't instantiate the worker threads until we actually put
      # work onto the queue.
      queue << 'empty msg'
    end
  end

  def test_stubbing_girl_friday_with_flexmock
    expected = Thread.current.to_s
    actual = nil
    processor = Proc.new do |msg|
      actual = Thread.current.to_s
    end
    async_test do |cb|
      queue = GirlFriday::Queue.new('flexmock', :size => 2, &processor)
      flexmock(queue).should_receive(:push).zero_or_more_times.and_return do |msg|
        processor.call(msg)
      end
      queue.push 'hello world!'
      assert_equal expected, actual
      queue.shutdown do
        cb.call
      end
    end
  end

end
