$LOAD_PATH << File.expand_path('./lib')
require 'benchmark'
require 'thread'
require 'girl_friday'
#require 'jruby-prof'

COUNT = 300_000
puts "Process #{COUNT} noop messages"
puts RUBY_DESCRIPTION

i = 0
incr = Proc.new do
  i += 1
end

#result = JRubyProf.profile do

  Benchmark.bm(25) do |x|
    x.report 'Process' do
      queue = GirlFriday::Queue.new(:test, :size => 5) do |msg|
        i += 1
      end
      COUNT.times do |y|
        queue << y
      end
      queue.wait_for_empty
      puts i
    end
  end
# end
#JRubyProf.print_tree_html(result, "call_tree.html")
