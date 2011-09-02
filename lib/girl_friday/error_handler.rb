module GirlFriday
  module ErrorHandler

    def self.default
      handlers = [Stderr]
      handlers << Hoptoad if defined?(HoptoadNotifier)
      handlers
    end

    class Stderr
      def handle(ex)
        $stderr.puts(ex)
        $stderr.puts(ex.backtrace.join("\n"))
      end
    end

    class Hoptoad
      def handle(ex)
        HoptoadNotifier.notify_or_ignore(ex)
      end
    end
    Airbrake = Hoptoad

  end
end
