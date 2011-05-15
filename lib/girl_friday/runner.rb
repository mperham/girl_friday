module GirlFriday
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
      
      @idle_workers = []
      @total_processed = @total_workers = 0
      @persister = opts[:store].new(name, (options[:store_config] || []))
    end
    
    # Add work to the queue
    def push(job)
      worker = @idle_workers.pop
      
      unless worker
        # Have we spawned all the workers allowed in the pool?
        if @total_workers == @size
          @persister << job
          return
        end
        
        # Spawn a new worker if we haven't hit the limit for the queue 
        worker = Worker.spawn_link(Celluloid.current_actor, &@processor)
        
        @total_workers += 1
      end
      
      worker.work! job
    end
    alias_method :<<, :push
    
    def status
      {
        :pid => $$,
        :pool_size => @size,
        :total_processed => @total_processed
      }
    end
    
    def shutdown
      @idle_workers.each { |worker| worker.terminate }
      terminate
    end
    
    def on_ready(worker)
      @total_processed += 1
      
      job = @persister.pop
      
      if job
        @worker.work! job
      else
        @idle_workers << worker
      end
    end    
    
    def inspect
      "#<GirlFriday::Runner processed: #{@total_processed}, pool size: #{@size}>"
    end
  end
end