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

module GirlFriday

  def self.status
    ObjectSpace.each_object(WorkQueue).inject({}) { |memo, queue| memo.merge(queue.status) }
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
    queues = []
    ObjectSpace.each_object(WorkQueue).each { |q| queues << q }
    count = queues.size
    m = Mutex.new
    var = ConditionVariable.new

    queues.each do |q|
      q.shutdown do |queue|
        m.synchronize do
          count -= 1
          var.signal if count == 0
        end
      end
    end

    m.synchronize do
      var.wait(m, timeout)
    end
    count
  end

  ##
  # Hook girl_friday into your process shutdown logic.
  # Calls shutdown! on the given signal.
  def self.install_shutdown_hook(signal="QUIT")
    trap(signal) do
      GirlFriday.shutdown!
    end
  end
end

