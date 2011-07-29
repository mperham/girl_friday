TEST_QUEUE = GirlFriday::WorkQueue.new(:test) do |msg|
  raise "Problem #{msg}" if msg % 9 == 0
  sleep 1
  print "test: #{msg} #{Thread.current}\n"
end

SOME_QUEUE = GirlFriday::WorkQueue.new(:some, :size => 2) do |msg|
  sleep 1
  print "some: #{msg} #{Thread.current}\n"
end
