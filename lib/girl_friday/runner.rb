module GirlFriday
  class Runner
    include Celluloid::Actor
    
    def initialize(options = {}, &block)
      @size = options[:size] || 5
      @processor = block
      
      @workers = []
      @size.times do
        @workers << Worker.spawn_link(Celluloid.current_actor, &@processor)
      end
    end
    
    def status
      {
        :pool_size => @size
      }
    end
    
    def shutdown
      @workers.each { |worker| worker.terminate }
      terminate
    end
    
    def on_ready(worker)
      puts "#{worker.inspect}: standing by"
    end    
  end
end