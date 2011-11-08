module GirlFriday

  ##
  # Batch represents a set of operations which can be processed
  # concurrently.  Asking for the results of the batch acts as a barrier:
  # the calling thread will block until all operations have completed.
  # Results are guaranteed to be returned in the
  # same order as the operations are given.
  #
  # Internally a girl_friday queue is created which limits the
  # number of concurrent operations based on the :size option.
  #
  # TODO Errors are not handled well at all.
  class Batch
    def initialize(enumerable=nil, options={}, &block)
      @queue = GirlFriday::Queue.new(:batch, options, &block)
      @complete = 0
      @size = 0
      @results = []
      if enumerable
        @size = enumerable.count
        @results = Array.new(@size)
      end
      @lock = Mutex.new
      @condition = ConditionVariable.new
      @frozen = false
      start(enumerable)
    end

    def results(timeout=nil)
      @frozen = true
      @lock.synchronize do
        @condition.wait(@lock, timeout) if @complete != @size
        @queue.shutdown
        @results
      end
    end

    def push(msg)
      raise ArgumentError, "Batch is frozen, you cannot push more items into it" if @frozen
      @lock.synchronize do
        @results << nil
        @size += 1
        index = @results.size - 1
        @queue.push(msg) do |result|
          completion(result, index)
        end
      end
    end
    alias_method :<<, :push

    private

    def start(operations)
      operations.each_with_index do |packet, index|
        @queue.push(packet) do |result|
          completion(result, index)
        end
      end if operations
    end

    def completion(result, index)
      @lock.synchronize do
        @complete += 1
        @results[index] = result
        @condition.signal if @complete == @size
      end
    end

  end
end
