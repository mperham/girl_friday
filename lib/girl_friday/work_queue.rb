module GirlFriday

  def self.status
    ObjectSpace.each_object(WorkQueue).inject({}) { |memo, queue| memo.merge(queue.status) }
  end

  class WorkQueue
    Ready = Struct.new(:this)
    Work = Struct.new(:msg, :callback)

    attr_reader :name
    def initialize(name, options={}, &block)
      @name = name
      @size = options[:size] || 5
      @processor = block
      @error_handler = (options[:error_handler] || ErrorHandler.default).new

      @ready_workers = []
      @extra_work = []
      @busy_workers = []
      @started_at = Time.now.to_i
      @total_processed = @total_errors = @total_queued = 0
      start
    end
  
    def push(work, &block)
      @total_queued += 1
      @actor << Work[work, block]
    end
    alias_method :<<, :push

    def status
      { @name => {
          :pid => $$,
          :pool_size => @size,
          :ready => @ready_workers.size,
          :busy => @busy_workers.size,
          :backlog => @extra_work.size,
          :total_queued => @total_queued,
          :total_processed => @total_processed,
          :total_errors => @total_errors,
          :uptime => Time.now.to_i - @started_at,
          :started_at => @started_at,
        }
      }
    end

    private

    def start
      @actor = Actor.spawn do
        supervisor = Actor.current
        work_loop = Proc.new do
          loop do
            work = Actor.receive
            result = @processor.call(work.msg)
            work.callback.call(result) if work.callback
            supervisor << Ready[Actor.current]
          end
        end

        Actor.trap_exit = true
        @size.times do |x|
          # start N workers
          @ready_workers << Actor.spawn_link(&work_loop)
        end

        begin
          loop do
            Actor.receive do |f|
              f.when(Ready) do |who|
                @total_processed += 1
                if work = @extra_work.pop
                  who.this << work
                  drain(@ready_workers, @extra_work)
                else
                  @busy_workers.delete(who.this)
                  @ready_workers << who.this
                end
              end
              f.when(Work) do |work|
                if worker = @ready_workers.pop
                  @busy_workers << worker
                  worker << work
                  drain(@ready_workers, @extra_work)
                else
                  @extra_work << work
                end
              end
              f.when(Actor::DeadActorError) do |exit|
                # TODO Provide current message contents as error context
                @total_errors += 1
                @ready_workers << Actor.spawn_link(&work_loop)
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

      def drain(ready, work)
        # give as much work to as many ready workers as possible
        todo = ready.size < work.size ? ready.size : work.size
        todo.times do
          worker = ready.pop
          @busy_workers << worker
          worker << work.pop
        end
      end
    end

  end
end