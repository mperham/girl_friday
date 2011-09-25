require 'weakref'
require 'thread'
begin
  # Rubinius
  require 'actor'
  require 'girl_friday/monkey_patches'
rescue LoadError
  # Others
  require 'girl_friday/actor'
end

require 'girl_friday/version'
require 'girl_friday/work_queue'
require 'girl_friday/error_handler'
require 'girl_friday/persistence'
require 'girl_friday/batch'

module GirlFriday

  @lock = Mutex.new

  def self.add_queue(ref)
    @lock.synchronize do
      @queues ||= []
      @queues.reject! { |q| !q.weakref_alive? }
      @queues << ref
    end
  end

  def self.remove_queue(ref)
    @lock.synchronize do
      @queues.delete ref
    end
  end

  def self.queues
    @queues || []
  end

  def self.status
    queues.inject({}) do |memo, queue|
      begin
        memo = memo.merge(queue.__getobj__.status)
      rescue WeakRef::RefError
      end
      memo
    end
  end

  ##
  # Notify girl_friday to shutdown ASAP.  Workers will not pick up any
  # new work; any new work pushed onto the queues will be pushed onto the
  # backlog (and persisted).  This method will block until all queues are
  # quiet or the timeout has passed.
  #
  # Note that shutdown! just works with existing queues.  If you create a
  # new queue, it will act as normal.
  def self.shutdown!(timeout=30)
    qs = queues.select { |q| q.weakref_alive? }
    count = qs.size

    if count > 0
      m = Mutex.new
      var = ConditionVariable.new

      qs.each do |q|
        next if !q.weakref_alive?
        begin
          q.__getobj__.shutdown do |queue|
            m.synchronize do
              count -= 1
              var.signal if count == 0
            end
          end
        rescue WeakRef::RefError
          m.synchronize do
            count -= 1
            var.signal if count == 0
          end
        end
      end

      m.synchronize do
        var.wait(m, timeout) if count != 0
      end
    end
    count
  end

end


unless defined?($testing)
  at_exit do
    GirlFriday.shutdown!
  end
end
