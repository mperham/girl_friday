module GirlFriday
  class ErrorHandler
    def handle(ex)
      $stderr.puts(ex)
      $stderr.puts(ex.backtrace.join("\n"))
    end
    
    def self.default
      defined?(HoptoadNotifier) ? Hoptoad : self
    end
  end
end

module GirlFriday
  class ErrorHandler
    class Hoptoad
      def handle(ex)
        HoptoadNotifier.notify_or_ignore(ex)
      end
    end
  end
end