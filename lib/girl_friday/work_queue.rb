module GirlFriday

  class WorkQueue
    Ready = Struct.new(:this)
    Work = Struct.new(:msg, :callback)
    Shutdown = Struct.new(:callback)

    attr_reader :name
    def initialize(name, options={}, &block)
      raise ArgumentError, "#{self.class.name} requires a block" unless block_given?
      @name = name.to_s
      @size = options[:size] || 5
      @processor = block
      @error_handler = (options[:error_handler] || ErrorHandler.default).new

      @shutdown = false
      @busy_workers = []
      @created_at = Time.now.to_i
      @total_processed = @total_errors = @total_queued = 0
      @persister = (options[:store] || Store::InMemory).new(name, (options[:store_config] || []))
      start
    end

    if defined?(Rails) && Rails.env.development?
      Rails.logger.debug "[girl_friday] Starting in single-threaded mode for Rails autoloading compatibility" if Rails.logger
      def push(work)
        result = @processor.call(work)
        yield result if block_given?
      end
    else
      def push(work, &block)
        @supervisor << Work[work, block]
      end
    end
    alias_method :<<, :push

    def status
      { @name => {
          :pid => $$,
          :pool_size => @size,
          :ready => ready_workers.size,
          :busy => @busy_workers.size,
          :backlog => @persister.size,
          :total_queued => @total_queued,
          :total_processed => @total_processed,
          :total_errors => @total_errors,
          :uptime => Time.now.to_i - @created_at,
          :created_at => @created_at,
        }
      }
    end

    # Busy wait for the queue to empty.
    # Useful for testing.
    def wait_for_empty
      while @persister.size != 0
        sleep 0.1
      end
    end

    def shutdown
      # Runtime state should never be modified by caller thread,
      # only the Supervisor thread.
      @supervisor << Shutdown[block_given? ? Proc.new : nil]
    end

    private

    def on_ready(who)
      @total_processed += 1
      if !@shutdown && work = @persister.pop
        who.this << work
        drain
      else
        @busy_workers.delete(who.this)
        ready_workers << who.this
        shutdown_complete if @shutdown && @busy_workers.size == 0
      end
    rescue => ex
      # Redis network error?  Log and ignore.
      @error_handler.handle(ex)
    end

    def shutdown_complete
      begin
        @when_shutdown.call(self) if @when_shutdown
      rescue Exception => ex
        @error_handler.handle(ex)
      end
    end

    def on_work(work)
      @total_queued += 1

      if !@shutdown && worker = ready_workers.pop
        @busy_workers << worker
        worker << work
        drain
      else
        @persister << work
      end
    rescue => ex
      # Redis network error?  Log and ignore.
      @error_handler.handle(ex)
    end

    def ready_workers
      @ready_workers ||= begin
        workers = []
        @size.times do |x|
          # start N workers
          workers << Actor.spawn_link(&@work_loop)
        end
        workers
      end
    end

    def start
      @supervisor = Actor.spawn do
        supervisor = Actor.current
        @work_loop = Proc.new do
          loop do
            work = Actor.receive
            result = @processor.call(work.msg)
            work.callback.call(result) if work.callback
            supervisor << Ready[Actor.current]
          end
        end

        Actor.trap_exit = true
        begin
          loop do
            Actor.receive do |f|
              f.when(Ready) do |who|
                on_ready(who)
              end
              f.when(Work) do |work|
                on_work(work)
              end
              f.when(Shutdown) do |stop|
                @shutdown = true
                @when_shutdown = stop.callback
                shutdown_complete if @shutdown && @busy_workers.size == 0
              end
              f.when(Actor::DeadActorError) do |exit|
                # TODO Provide current message contents as error context
                @total_errors += 1
                @busy_workers.delete(exit.actor)
                ready_workers << Actor.spawn_link(&@work_loop)
                @error_handler.handle(exit.reason)
              end
            end
          end

        rescue Exception => ex
          $stderr.print "Fatal error in girl_friday: supervisor for #{name} died.\n"
          $stderr.print("#{ex}\n")
          $stderr.print("#{ex.backtrace.join("\n")}\n")
        end
      end
    end

    def drain
      # give as much work to as many ready workers as possible
      ps = @persister.size
      todo = ready_workers.size < ps ? ready_workers.size : ps
      todo.times do
        worker = ready_workers.pop
        @busy_workers << worker
        worker << @persister.pop
      end
    end

  end
  Queue = WorkQueue
end
