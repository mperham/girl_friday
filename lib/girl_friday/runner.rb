module GirlFriday
  Job = Struct.new(:params, :callback)
  
  class Runner
    include Celluloid::Actor
    
    def initialize(name, options = {}, &block)
      opts = {
        :size => 5,
        :error_handler => ErrorHandler.default,
        :store => Store::InMemory,
        :store_config => []
      }.merge(options)
      
      @name = name.to_s
      @size = opts[:size]
      @processor = block
      @error_handler = opts[:error_handler].new
      
      @created_at = Time.now.to_i
      @ready_workers = []
      @busy_workers = 0
      @total_processed = @total_errors = @total_queued = @total_workers = 0
      @persister = opts[:store].new(name, (options[:store_config] || []))
      @total_queued = @persister.size
      
      drain
    end
    
    # Add work to the queue
    def push(params = {}, &callback)
      @total_queued += 1
      job = Job[params, callback]
      
      if worker = reserve_worker
        worker.work! job
      else
        @persister << job
      end
    end
    alias_method :<<, :push
    
    # Obtain the queue status
    def status
      {
        :pid => $$,
        :pool_size => @size,
        :ready => @ready_workers.size,
        :busy => @busy_workers,
        :backlog => @persister.size,
        :total_queued => @total_queued,
        :total_processed => @total_processed,
        :total_errors => @total_errors,
        :uptime => Time.now.to_i - @created_at,
        :created_at => @created_at
      }
    end
    
    # Terminate the work queue
    def shutdown
      @ready_workers.each { |worker| worker.terminate }
      terminate
    end
    
    # Handle ready events from workers
    def on_ready(worker, error)
      @total_processed += 1
      
      if job = @persister.pop
        @worker.work! job
      else
        @busy_workers -= 1
        @ready_workers << worker
      end
      
      on_error error if error
    end
    
    # Handle exit messages from workers
    def on_error(reason)
      @total_errors += 1
      @error_handler.handle reason
    end
    
    def inspect
      fields = {
        :processed => @total_processed,
        :backlog   => @persister.size,
        :pool      => @size
      }
      
      str = "#<GirlFriday::Runner "
      str << fields.map { |k, v| "#{k}=#{v}" }.join(', ')
      str << ">"
    end
    
    # Reserve a worker, either from the pool or by creating one
    def reserve_worker
      if worker = @ready_workers.pop
        @busy_workers += 1
        return worker
      end
      
      # If we're reached the pool size we're at capacity
      return if @total_workers == @size
        
      # Spawn a new worker if we haven't hit the limit for the queue 
      @total_workers += 1
      @busy_workers += 1
      
      Worker.spawn_link(Celluloid.current_actor, &@processor)
    end
    
    # Drain the work queue until we're at capacity
    def drain
      until @persister.size == 0
        break unless worker = reserve_worker
        worker.work! @persister.pop
      end
    end
  end
end