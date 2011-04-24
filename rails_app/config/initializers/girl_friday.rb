TEST_QUEUE = GirlFriday::WorkQueue.new(:test) do |msg|
  raise "Problem #{msg}" if msg % 7 == 0
  print "#{msg} #{Thread.current}\n"
end