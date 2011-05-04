module GirlFriday
  module Store

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
        @key = "girl_friday-#{name}-#{environment}"
      end

      def push(work)
        val = Marshal.dump(work)
        redis.rpush(@key, val)
      end
      alias_method :<<, :push

      def pop
        val = redis.lpop(@key)
        Marshal.load(val) if val
      end

      def size
        redis.llen(@key)
      end

      private

      def environment
        ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'none'
      end

      def redis
        @redis ||= ::Redis.new(*@opts)
      end
    end
  end
end
    