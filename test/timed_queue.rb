require 'thread'
require 'timeout'

class Mutex
  public :sleep
end

# Standard queue with a pop that has a timeout.
class TimedQueue
  def initialize
    @que = []
    @waiting = []
    @mutex = Mutex.new
  end

  def push(obj)
    @mutex.synchronize {
      @que.push obj
      begin
        t = @waiting.shift
        t.wakeup if t
      rescue ThreadError
        retry
      end
    }
  end

  alias_method :<<, :push

  def timed_pop(timeout=0.5)
    @mutex.synchronize {
      while true
        if @que.empty?
          @waiting.push Thread.current
          raise Timeout::Error if @mutex.sleep(timeout) != 0
        else
          return @que.shift
        end
      end
    }
  end

  def empty?
    @que.empty?
  end

  def clear
    @que.clear
  end

  def length
    @que.length
  end
  alias_method :size, :length

end