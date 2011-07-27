require 'thread'
require 'ostruct'

BlockingArray = Queue

class Actor
  class NotActorError < RuntimeError; end

  class << self
    alias_method :private_new, :new
    private :private_new

    def current
      x = Thread.current[:__current_actor__]
      raise NotActorError, "No actor associated with current thread" unless x
      x
    end

    def myself
      Thread.current[:__current_actor__]
    end

    # Spawn a new Actor that will run in its own thread
    def new(*args, &block)
      raise ArgumentError, "no block given" unless block
      spawned = Queue.new
      Thread.new do
        private_new do |actor|
          Thread.current[:__current_actor__] = actor
          spawned << actor
          actor.instance_exec(&block)
        end
      end
      spawned.pop
    end
  end

  def initialize
    @mailbox = BlockingArray.new
    @alive = true

    watchdog { yield self }
  end

  Message = Struct.new(:sender, :msg)

  def deliver(message)
    raise DeadActorError, "I'm dead, bro" unless @alive
    @mailbox << Message[Actor.myself, Marshal.dump(message)]
    self
  end
  alias_method :<<, :deliver

  def receive
    if block_given?
      @message = @mailbox.shift
      yield Marshal.load(@message.msg)
    else
      @message = @mailbox.shift
      Marshal.load(@message.msg)
    end
  end

  def sender
    @message.sender
  end

  private

  def watchdog
    yield
  rescue Exception
    puts $!.message
    puts $!.backtrace.join("\n")
  ensure
    @alive = false
    @mailbox.clear
  end
end
