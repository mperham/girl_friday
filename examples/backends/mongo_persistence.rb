require 'mongo'

# Add index on created_at

module GirlFriday
  module Store
    class Mongo
      def initialize(name, options)
        @opts = options
        @key = "girl_friday-#{name}-#{environment}"
      end

      def push(work)
        val = Marshal.dump(work)
        collection.insert({ "work" => val })
      end
      alias_method :<<, :push

      def pop
        begin
          val = collection.find_and_modify(:sort => [['$natural', 1]],
                                           :remove => true)
          Marshal.load(val["work"]) if val
        rescue
          # rescuing
          # Database command 'findandmodify' failed: {"errmsg"=>"No matching object found", "ok"=>0.0}
        end
      end

      def size
        collection.size
      end

      private

      def environment
        ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'none'
      end

      def connection
        @connection ||= (@opts.delete(:mongo) || ::Mongo::Connection.new("localhost", 27017, :pool_size => 5))
      end

      def db
        db = @opts.delete(:db) || "girl_friday"
        @db ||= connection[db]
      end

      def collection
        @collection ||= db[@key]
      end

    end
  end
end
