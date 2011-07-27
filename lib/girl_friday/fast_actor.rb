require 'thread'

puts "Loading fast_actor"
include Java
include_class Java::java.util.concurrent.ConcurrentLinkedQueue
include_class Java::java.util.concurrent.ConcurrentHashMap
include_class Java::java.util.concurrent.LinkedBlockingQueue
ConcurrentMap = java.util.concurrent.ConcurrentHashMap
BlockingArray = java.util.concurrent.LinkedBlockingQueue
class BlockingArray
  alias_method :shift, :take
  alias_method :<<, :put
end

class Actor
  class << self
    alias_method :private_new, :new
    private :private_new

    def current
      Thread.current[:__current_actor__] ||= private_new
    end

    # Spawn a new Actor that will run in its own thread
    def spawn(*args, &block)
      raise ArgumentError, "no block given" unless block
      spawned = Queue.new
      Thread.new do
        private_new do |actor|
          Thread.current[:__current_actor__] = actor
          spawned << actor
          block.call(*args)
        end
      end
      spawned.pop
    end
    alias_method :new, :spawn
    alias_method :spawn_link, :spawn

    def receive
      current._receive
    end
  end

  def initialize
    @mailbox = BlockingArray.new
    @alive = true

    watchdog { yield self }
  end


  def send(message)
    return self unless @alive
    @mailbox << message
    self
  end
  alias_method :<<, :send

  def _receive
    @mailbox.shift
  end

  def watchdog
    begin
      yield
    rescue Exception
    ensure
      @alive = false
      @mailbox = nil
    end
  end
  private :watchdog


end
