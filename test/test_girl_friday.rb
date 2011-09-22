require 'helper'

class TestGirlFriday < MiniTest::Unit::TestCase

  describe 'GirlFriday' do
    after do
      GirlFriday.shutdown!
    end

    describe '.status' do
      before do
        q1 = GirlFriday::Queue.new(:q1) do; end
        q2 = GirlFriday::Queue.new(:q2) do; end
      end
      it 'provides a status structure for each live queue' do
        hash = GirlFriday.status
        assert_kind_of Hash, hash
        assert_equal 2, GirlFriday.queues.size
        assert_equal 2, hash.size
      end
    end

    describe '.shutdown!' do
      before do
        q1 = GirlFriday::Queue.new(:q1) do; end
        q2 = GirlFriday::Queue.new(:q2) do; end
      end
      it 'provides a status structure for each live queue' do
        a = Time.now
        assert_equal 0, GirlFriday.shutdown!
        assert_in_delta 0, Time.now - a, 0.1
        assert_equal 0, GirlFriday.queues.size
      end
    end
  end

end
