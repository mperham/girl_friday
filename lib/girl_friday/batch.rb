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
    def initialize(enumerable, options, &block)
      @queue = GirlFriday::Queue.new(:batch, options, &block)
      @complete = 0
      @size = enumerable.count
      @results = Array.new(@size)
      @lock = Mutex.new
      @condition = ConditionVariable.new
      start(enumerable)
    end

    def results(timeout=nil)
      @lock.synchronize do
        @condition.wait(@lock, timeout) if @complete != @size
        @results
      end
    end

    private

    def start(operations)
      operations.each_with_index do |packet, index|
        @queue.push(packet) do |result|
          @lock.synchronize do
            @complete += 1
            @results[index] = result
            @condition.signal if @complete == @size
          end
        end
      end
    end

  end
end
