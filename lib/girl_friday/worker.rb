module GirlFriday
  # Job processing actor
  class Worker
    include Celluloid::Actor
    
    def initialize(runner, &processor)
      @runner, @processor = runner, processor
    end
    
    def work(job)
      begin
        result = @processor[job.params]
        job.callback.call result if job.callback
      rescue Exception => error
      end
      
      @runner.on_ready! Celluloid.current_actor, error
    end
    
    def inspect
      "#<GirlFriday::Worker:#{object_id}>"
    end
  end
end