require 'helper'

class TestBatch < MiniTest::Unit::TestCase

  def test_simple_batch_operation
    work = [0.5] * 10
    a = Time.now
    batch = GirlFriday::Batch.new(work, :size => 10) do |msg|
      sleep msg
      Time.now
    end
    b = Time.now
    # Initial creation should do no work
    assert_in_delta(0.0, (b - a), 0.1)

    # asking for the results should block
    results = batch.results(1.0)
    c = Time.now
    assert_in_delta(0.5, (c - b), 0.3)

    assert_equal 10, results.size
    assert_kind_of Time, results[0]
  end

  def test_batch_timeout
    work = [0.1] * 4
    work[2] = 0.4
    batch = GirlFriday::Batch.new(work, :size => 4) do |msg|
      sleep msg
      'x'
    end
    results = batch.results(0.3)
    assert_equal 'x', results[0]
    assert_equal 'x', results[1]
    assert_nil results[2]
    assert_equal 'x', results[3]

    # Necessary to work around a Ruby 1.9.2 bug
    # http://redmine.ruby-lang.org/issues/5342
    sleep 0.1
  end

  def test_empty_batch
    batch = GirlFriday::Batch.new(nil, :size => 4) do |msg|
      sleep msg
      'x'
    end
    values = batch.results
    values.must_be_kind_of Array
    values.must_equal []
  end

  def test_streaming_batch_api
    batch = GirlFriday::Batch.new(nil, :size => 4) do |msg|
      sleep msg
      'x'
    end
    a = Time.now
    batch << 0.1
    batch << 0.1
    batch << 0.1
    batch << 0.1
    values = batch.results
    b = Time.now
    values.must_be_kind_of Array
    values.must_equal %w(x x x x)
    assert_in_delta 0.2, (b - a), 0.1

    assert_raises ArgumentError do
      batch << 0.1
    end
  end
end
