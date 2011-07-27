$LOAD_PATH << File.expand_path('./lib')
require 'benchmark'
require 'fast_actor'
#require 'jruby-prof'

COUNT = 100_000
puts "Process #{COUNT} noop messages"
puts RUBY_DESCRIPTION

include_class Java::java.util.concurrent.atomic.AtomicInteger
i = java.util.concurrent.atomic.AtomicInteger.new
done = 0
pong = nil

ping = Actor.new do
  loop do
    receive do |msg|
      pong << (msg + 1)
    end
  end
end

pong = Actor.new do
  loop do
    receive do |msg|
      if msg > 100_000
        done = msg
      else
        sender << (msg + 1)
      end
    end
  end
end

Benchmark.bm(25) do |x|
  x.report 'FastActors' do
    ping << 0
    loop do
      break if done != 0
      sleep 0.1
    end
    puts done
  end
end
