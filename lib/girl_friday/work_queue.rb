
module GirlFriday
  class WorkQueue
    Ready = Struct.new(:this)
    Work = Struct.new(:msg, :callback)

    attr_reader :name
    def initialize(name, options={}, &block)
      @name = name
      @error_handler = (options[:error_handler] || ErrorHandler.default).new
      create_pool(options[:size] || 5, block)
    end
  
    def push(work, &block)
      @supervisor << Work[work, block]
    end
    alias_method :<<, :push

    private
  
    def drain(ready, work)
      # give as much work to as many ready workers as possible
      todo = ready.size < work.size ? ready.size : work.size
      todo.times do
        ready.pop << work.pop
      end
    end

    def create_pool(size, processor)
      @supervisor = Actor.spawn do
        supervisor = Actor.current
        ready_workers = []
        extra_work = []
        work_loop = Proc.new do
          loop do
            work = Actor.receive
            result = processor.call(work.msg)
            work.callback.call(result) if work.callback
            supervisor << Ready[Actor.current]
          end
        end

        Actor.trap_exit = true
        size.times do |x|
          # start N workers
          ready_workers << Actor.spawn_link(&work_loop)
        end

        begin
          loop do
            Actor.receive do |f|
              f.when(Ready) do |who|
                if work = extra_work.pop
                  who.this << work
                  drain(ready_workers, extra_work)
                else
                  ready_workers << who.this
                end
              end
              f.when(Work) do |work|
                if worker = ready_workers.pop
                  worker << work
                  drain(ready_workers, extra_work)
                else
                  extra_work << work
                end
              end
              f.when(Actor::DeadActorError) do |exit|
                # TODO Provide current message contents as error context
                @error_handler.handle(exit.reason)
                ready_workers << Actor.spawn_link(&work_loop)
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

  end
end