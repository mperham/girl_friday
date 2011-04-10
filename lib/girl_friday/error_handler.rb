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
        HoptoadNotifier.notify(ex)
      end
    end
  end
end