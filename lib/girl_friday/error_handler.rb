module GirlFriday
  module ErrorHandler

    def self.default
      handlers = [Stderr]
      handlers << Airbrake if defined?(::Airbrake)
      handlers
    end

    class Stderr
      def handle(ex)
        $stderr.puts(ex)
        $stderr.puts(ex.backtrace.join("\n"))
      end
    end

    class Airbrake
      def handle(ex)
        ::Airbrake.notify_or_ignore(ex)
      end
    end
  end
end
