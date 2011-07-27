require 'helper'

class TestGirlFriday < MiniTest::Unit::TestCase

  class TestErrorHandler
    include MiniTest::Assertions
  end

  def test_should_process_messages
    async_test do |cb|
      queue = GirlFriday::WorkQueue.new('test') do |msg|
        assert_equal 'foo', msg[:text]
        cb.call
      end
      queue.push(:text => 'foo')
    end
  end

  def test_should_handle_worker_error
    async_test do |cb|
      TestErrorHandler.send(:define_method, :handle) do |ex|
        assert_equal 'oops', ex.message
        assert_equal 'RuntimeError', ex.class.name
        cb.call
      end

      queue = GirlFriday::WorkQueue.new('test', :error_handler => TestErrorHandler) do |msg|
        raise 'oops'
      end
      queue.push(:text => 'foo')
    end
  end

  def test_should_call_callback_when_complete
    async_test do |cb|
      queue = GirlFriday::WorkQueue.new('test', :size => 1) do |msg|
        assert_equal 'foo', msg[:text]
        'camel'
      end
      queue.push(:text => 'foo') do |result|
        assert_equal 'camel', result
        cb.call
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

    async_test do |cb|
      count = 0
      queue = GirlFriday::WorkQueue.new('image_crawler', :size => 3) do |msg|
        incr.call
        cb.call if count == total
      end
      total.times do |idx|
        queue.push(:text => 'foo')
      end

      sleep 0.01
      actual = GirlFriday.status
      refute_nil actual
      refute_nil actual['image_crawler']
      metrics = actual['image_crawler']
      assert metrics[:total_queued] > 0
      assert metrics[:total_queued] <= total
      assert_equal 3, metrics[:pool_size]
      assert_equal 3, metrics[:busy]
      assert_equal 0, metrics[:ready]
      assert(metrics[:backlog] > 0)
      assert(metrics[:total_processed] > 0)
    end
  end

  def test_should_persist_with_redis
    begin
      require 'redis'
      redis = Redis.new
      redis.flushdb
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

    async_test do |cb|
      queue = GirlFriday::WorkQueue.new('test', :size => 2, :store => GirlFriday::Store::Redis) do |msg|
        incr.call
        cb.call if count == total
      end
      total.times do
        queue.push(:text => 'foo')
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

      count = GirlFriday.shutdown!
      assert_equal 0, count
      s = queue.status
      assert_equal 0, s['shutdown'][:busy]
      assert_equal 2, s['shutdown'][:ready]
      assert(s['shutdown'][:backlog] > 0)
      cb.call
    end
  end

  def test_should_create_workers_lazily
    async_test do |cb|
      queue = GirlFriday::Queue.new('shutdown', :size => 2) do |msg|
        assert_equal 1, queue.instance_variable_get(:@ready_workers).size
        cb.call
      end
      refute queue.instance_variable_defined?(:@ready_workers)
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
    queue = GirlFriday::Queue.new('shutdown', :size => 2, &processor)
    flexmock(queue).should_receive(:push).zero_or_more_times.and_return do |msg|
      processor.call(msg)
    end
    queue.push 'hello world!'
    assert_equal expected, actual
  end

end
