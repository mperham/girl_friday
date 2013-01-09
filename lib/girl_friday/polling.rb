require 'ruby-debug'

module GirlFriday
  module Polling
    DefaultPollingInterval = 15

    Shutdown = Struct.new(:callback)

    @shutting_down = true

    def self.polling_interval
      @polling_interval ||= DefaultPollingInterval
    end

    def self.polling_interval=(value)
      raise ArgumentError, "Infinite time between polls really is not polling at all is it?" if value == 0
      @polling_interval = value
    end

    def self.begin_polling
      @shutting_down = false
      @pollster ||= Actor.spawn do
        Thread.current[:label] = "girl-friday-pollster"
        begin
          polling_loop
        rescue Exception => ex
          $stderr.print "Fatal error in girl_friday: pollster died.\n"
          $stderr.print("#{ex}\n")
          $stderr.print("#{ex.backtrace.join("\n")}\n")
        end
      end
      @pollster << :poll
      polling?
    end

    def self.end_polling(&block)
      @shutting_down = true
      pollster << Shutdown[block] unless pollster.nil?
    end

    def self.polling?
      !shutting_down? && !!pollster
    end

    def self.shutting_down?
      @shutting_down
    end

    private

    def self.polling_loop
      loop do
        Actor.receive do |f|
          f.when(:poll) do
            sleep polling_interval
            GirlFriday.check_for_work
            pollster << :poll
          end
          f.when(Shutdown) do |stop|
            @pollster = nil
            begin
              stop.callback.call(self) unless stop.callback.nil?
            rescue Exception => ex
              handle_error(ex)
            end
            return
          end
        end
      end
    end

    def self.pollster
      @pollster ||= nil
    end
  end
end