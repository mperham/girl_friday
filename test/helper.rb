$testing = true
require 'test/unit'
require 'thread'
require 'timeout'

require 'girl_friday'

puts RUBY_DESCRIPTION

if RUBY_VERSION < '1.9'
  class Mutex
    public :sleep
  end
end

class Queue
  if RUBY_VERSION > '1.9'

    def timed_pop(timeout=0.5)
      @mutex.synchronize do
        while true
          if @que.empty?
            @waiting.push Thread.current
            raise Timeout::Error if @mutex.sleep(timeout) != 0
          else
            return @que.shift
          end
        end
      end
    end

  elsif RUBY_ENGINE == "rbx"

    def timed_pop(timeout=0.5)
      while true
        @mutex.synchronize do
          #FIXME: some code in net or somewhere violates encapsulation
          #and demands that a waiting queue exist for Queue, as a result
          #we have to do a linear search here to remove the current Thread.
          @waiting.delete(Thread.current)
          if @que.empty?
            @waiting.push Thread.current
            @resource.wait(@mutex, timeout)
          else
            retval = @que.shift
            @resource.signal
            return retval
          end
        end
      end
    end

  end
  
end

class Test::Unit::TestCase

  def async_test(time=0.5)
    q = Queue.new
    yield Proc.new { q << nil }
    q.timed_pop(time)
  end

end