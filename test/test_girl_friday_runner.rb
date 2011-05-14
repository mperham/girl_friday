require 'helper'

class TestGirlFridayRunner < MiniTest::Unit::TestCase

  class TestErrorHandler
    include MiniTest::Assertions
  end

  def test_honor_size_option
    size = 42
    
    runner = GirlFriday::Runner.spawn :size => size
    assert_equal size, runner.status[:pool_size]
  end
  
  def test_shutdown
    runner = GirlFriday::Runner.spawn
    runner.shutdown
    
    sleep 0.1 # hax: give it some time to shut down
    
    assert_equal false, runner.alive?
  end
end