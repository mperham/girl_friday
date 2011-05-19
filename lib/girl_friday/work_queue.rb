module GirlFriday
  class WorkQueue
    attr_reader :name
    def initialize(name, options={}, &block)
      @name = name.to_s
      @supervisor = GirlFriday::Runner.supervise_as(@name, @name, options, &block)
      GirlFriday.queues << WeakRef.new(self)
    end
  
    def push(work, &block)
      Celluloid::Actor[@name].push(work, &block)
    end
    alias_method :<<, :push

    def status
      Celluloid::Actor[@name].status
    end

    def shutdown(&block)
      @supervisor.terminate(&block)
    end

    def inspect
      current_status = Celluloid::Actor[@name].inspect
      
      fields = {
        :processed => current_status[:total_processed],
        :backlog   => current_status[:backlog],
        :pool      => current_status[:pool_size],
        :uptime    => current_status[:uptime]
      }

      str = "#<GirlFriday::WorkQueue[@name] "
      str << fields.map { |k, v| "#{k}=#{v}" }.join(', ')
      str << ">"
    end
  end
  Queue = WorkQueue
end