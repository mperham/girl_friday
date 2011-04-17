module GirlFriday
  module Persistence

    class InMemory
      def initialize(name, options)
        @backlog = []
      end

      def push(work)
        @backlog << work
      end
      alias_method :<<, :push
      
      def pop
        @backlog.pop
      end
      
      def size
        @backlog.size
      end
    end
    
    class Redis
      def initialize(name, options)
        @opts = options
        @key = "girl_friday-#{name}"
      end

      def push(work)
        redis.rpush(@key)
      end
      alias_method :<<, :push

      def pop
        redis.lpop(@key)
      end

      def size
        redis.llen(@key)
      end

      private

      def redis
        @redis ||= Redis.new(*@opts)
      end
    end
  end
end
    