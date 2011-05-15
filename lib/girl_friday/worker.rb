module GirlFriday
  class Worker
    include Celluloid::Actor
    
    def initialize(runner, &processor)
      @runner, @processor = runner, processor
    end
    
    def work(params)
      @processor[params]
    end
    
    def inspect
      "#<GirlFriday::Worker:#{object_id}>"
    end
  end
end