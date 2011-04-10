require 'helper'

class TestGirlFriday < Test::Unit::TestCase
  
  def test_should_process_messages
    async_test do |cb|
      queue = GirlFriday::WorkQueue.new('test') do |msg|
        assert_equal 'foo', msg[:text]
        cb.call
      end
      queue.push(:text => 'foo')
    end
  end
  
  class TestErrorHandler
    include Test::Unit::Assertions
  end
  
  def test_should_handle_worker_error
    async_test do |cb|
      TestErrorHandler.send(:define_method, :handle) do |ex|
        assert ex.is_a?(RuntimeError)
        assert_equal 'oops', ex.message
        cb.call
      end

      queue = GirlFriday::WorkQueue.new('test', :error_handler => TestErrorHandler) do |msg|
        raise 'oops'
      end
      queue.push(:text => 'foo')
    end
  end

end