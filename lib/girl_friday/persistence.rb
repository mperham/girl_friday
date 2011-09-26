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
        @backlog.shift
      end

      def size
        @backlog.size
      end
    end

    class Redis
      def initialize(name, options)
        @opts = options
        raise ArgumentError, "you must pass in a :pool" unless @opts[:pool]
        @key = "girl_friday-#{name}-#{environment}"
      end

      def push(work)
        val = Marshal.dump(work)
        redis { |r| r.rpush(@key, val) }
      end
      alias_method :<<, :push

      def pop
        val = redis { |r| r.lpop(@key) }
        Marshal.load(val) if val
      end

      def size
        redis { |r| r.llen(@key) }
      end

      private

      def environment
        ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'none'
      end

      def redis
        @redis ||= @opts.delete(:pool)
        @redis.with do |pooled|
          yield pooled
        end
      end
    end

  end
end
