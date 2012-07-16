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
      @error_handlers = (Array(options[:error_handler] || ErrorHandler.default)).map(&:new)

      @shutdown = false
      @shutting_down = false
      @busy_workers = []
      @ready_workers = nil
      @created_at = Time.now.to_i
      @total_processed = @total_errors = @total_queued = 0
      @persister = (options[:store] || Store::InMemory).new(name, (options[:store_config] || {}))
      @weakref = WeakRef.new(self)
      start
      GirlFriday.add_queue @weakref
    end

    def self.immediate!
      alias_method :push, :push_immediately
      alias_method :<<, :push_immediately
    end

    def self.queue!
      alias_method :push, :push_async
      alias_method :<<, :push_async
    end

    def push_immediately(work, &block)
      result = @processor.call(work)
      return yield result if block
      result
    end

    def push_async(work, &block)
      @supervisor << Work[work, block]
    end
    alias_method :push, :push_async
    alias_method :<<, :push_async

    def status
      { @name => {
          :pid => $$,
          :pool_size => @size,
          :ready => @ready_workers ? @ready_workers.size : 0,
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
      until @persister.size == 0
        sleep 0.1
      end
    end

    def shutdown(&block)
      # Runtime state should never be modified by caller thread,
      # only the Supervisor thread.
      @supervisor << Shutdown[block]
    end

    def working?
      @busy_workers.size > 0
    end

    private

    def running?
      !@shutdown
    end

    def handle_error(ex)
      # Redis network error?  Log and ignore.
      @error_handlers.each { |handler| handler.handle(ex) }
    end

    def on_ready(who)
      @total_processed += 1
      if !shutting_down? && running? && work = @persister.pop
        who.this << work
        drain
      else
        @busy_workers.delete(who.this)
        ready_workers << who.this
      end
    rescue => ex
      handle_error(ex)
    end

    def shutdown_complete
      begin
        @when_shutdown.call(self) if @when_shutdown
      rescue Exception => ex
        handle_error(ex)
      end
    end

    def shutting_down?
      !!@shutting_down
    end

    def on_work(work)
      @total_queued += 1
      if !shutting_down? && running? && worker = ready_workers.pop
        @busy_workers << worker
        worker << work
        drain
      else
        @persister << work
      end
    rescue => ex
      handle_error(ex)
    end

    def ready_workers
      # start N workers
      @ready_workers ||= Array.new(@size) { Actor.spawn_link(&@work_loop) }
    end

    def start
      @supervisor = Actor.spawn do
        Thread.current[:label] = "#{name}-supervisor"
        supervisor = Actor.current
        @work_loop = Proc.new do
          Thread.current[:label] = "#{name}-worker"
          while running? do
            work = Actor.receive
            if running?
              result = @processor.call(work.msg)
              work.callback.call(result) if work.callback
              supervisor << Ready[Actor.current]
            end
          end
        end

        Actor.trap_exit = true
        begin
          supervisor_loop
        rescue Exception => ex
          $stderr.print "Fatal error in girl_friday: supervisor for #{name} died.\n"
          $stderr.print("#{ex}\n")
          $stderr.print("#{ex.backtrace.join("\n")}\n")
        end
      end
    end

    def drain
      # give as much work to as many ready workers as possible
      todo = [@persister.size, ready_workers.size].min
      todo.times do
        worker = ready_workers.pop
        @busy_workers << worker
        worker << @persister.pop
      end
    end

    def supervisor_loop
      loop do
        Actor.receive do |f|
          f.when(Ready) do |who|
            on_ready(who)
          end
          f.when(Work) do |work|
            on_work(work)
          end
          f.when(Shutdown) do |stop|
            @shutting_down = true
            if !working?
              @shutdown = true
              @when_shutdown = stop.callback
              @busy_workers.each { |w| w << stop }
              ready_workers.each { |w| w << stop }
              shutdown_complete
              GirlFriday.remove_queue @weakref
              return
            else
              Thread.pass
              shutdown(&stop.callback)
            end
          end
          f.when(Actor::DeadActorError) do |ex|
            if running?
              # TODO Provide current message contents as error context
              @total_errors += 1
              @busy_workers.delete(ex.actor)
              ready_workers << Actor.spawn_link(&@work_loop)
              handle_error(ex.reason)
              drain
            end
          end
        end
      end
    end
  end

  Queue = WorkQueue
end
