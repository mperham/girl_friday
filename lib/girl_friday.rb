require 'weakref'
require 'thread'

require 'girl_friday/version'
require 'girl_friday/work_queue'
require 'girl_friday/error_handler'
require 'girl_friday/persistence'
require 'girl_friday/batch'

begin
  # Rubinius or JRuby
  require 'rubinius/actor'
  GirlFriday::WorkQueue::Actor = Rubinius::Actor
rescue RuntimeError
  # Rubinius::Actor will raise a RuntimeError when
  # required on !(Rubinius || JRuby)
  require 'girl_friday/actor'
end

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
    @queues ||= []
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

  # Asks each queue to check with its persistence store for work
  def self.check_for_work
    queues.each do |queue|
      begin
        queue.__getobj__.check_for_work
      rescue WeakRef::RefError
      end
    end
  end

  def self.polling_interval
    @polling_interval ||= 15
  end

  def self.polling_interval=(value)
    @polling_interval = value
  end

  def self.begin_polling
    @pollster ||= Thread.new do
      loop do
        sleep polling_interval
        check_for_work
      end
    end
    polling?
  end

  def self.end_polling
    unless pollster.nil?
      pollster.kill
      @pollster = nil
    end
  end

  def self.polling?
    !!(!pollster.nil? && ['sleep', 'run'].include?(@pollster.status))
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
    end_polling
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

  private

  def self.pollster
    @pollster ||= nil
  end

end
