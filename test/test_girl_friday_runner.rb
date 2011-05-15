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
    
    begin
      runner.status
    rescue => ex
    end
    
    assert_equal Celluloid::DeadActorError, ex.class
  end
end