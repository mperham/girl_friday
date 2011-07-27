require 'benchmark'
require 'celluloid'

class Ping
  include Celluloid

  def ping(count)
    Celluloid::Actor[:pong].pong!(count + 1)
  end
end

class Pong
  include Celluloid

  def pong(count)
    return signal(:done, count) if count > 100_000
    Celluloid::Actor[:ping].ping!(count + 1)
  end

  def wait_for_end
    wait :done
  end
end


Celluloid::Actor[:ping] = ping = Ping.new
Celluloid::Actor[:pong] = pong = Pong.new

Benchmark.bm(25) do |x|
  x.report('Celluloid') do
    ping.ping! 0
    puts pong.wait_for_end
  end
end
