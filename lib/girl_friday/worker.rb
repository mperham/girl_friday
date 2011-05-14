module GirlFriday
  class Worker
    include Celluloid::Actor
    
    def initialize(runner, &processor)
      @runner, @processor = runner, processor
    end
  end
end