require 'helper'

class TestBatch < MiniTest::Unit::TestCase

  def test_simple_batch_operation
    work = [1] * 10
    a = Time.now
    batch = GirlFriday::Batch.new(work, :size => 10) do |msg|
      sleep msg
      Time.now
    end
    b = Time.now
    # Initial creation should do no work
    assert_in_delta(0.0, (b - a), 0.1)

    # asking for the results should block
    results = batch.results(2.0)
    c = Time.now
    assert_in_delta(1.0, (c - b), 0.1)
    assert_equal 10, results.size
    assert_kind_of Time, results[0]
  end
end
