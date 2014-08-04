require 'helper'

class TestGirlFriday < MiniTest::Unit::TestCase

  describe 'GirlFriday' do
    before do
      GirlFriday::Polling.polling_interval = 1
    end
    after do
      GirlFriday.shutdown!
    end

    describe '.status' do
      before do
        GirlFriday::Queue.new(:q1) do; end
        GirlFriday::Queue.new(:q2) do; end
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
        GirlFriday::Queue.new(:q1) do; end
        GirlFriday::Queue.new(:q2) do; end
      end
      it 'provides a status structure for each live queue' do
        a = Time.now
        assert_equal 0, GirlFriday.shutdown!
        assert_in_delta 0, Time.now - a, 0.1
        assert_equal 0, GirlFriday.queues.size
      end
      it 'stops polling' do
        GirlFriday::Polling.begin_polling
        GirlFriday.shutdown!
        assert !GirlFriday::Polling.polling?
      end
    end

    describe '.begin_polling' do
      it 'does not poll unless started' do
        assert !GirlFriday::Polling.polling?
      end
      it 'polls once started' do
        assert !GirlFriday::Polling.polling?
        GirlFriday::Polling.begin_polling
        assert GirlFriday::Polling.polling?
      end
    end

    describe '.end_polling' do
      before do
        GirlFriday::Polling.begin_polling
      end
      it 'stops polling' do
        GirlFriday::Polling.end_polling
        assert !GirlFriday::Polling.polling?
      end
    end

    describe '.check_for_work' do
      before do
        GirlFriday::Queue.new(:q1) do; end
        GirlFriday::Queue.new(:q2) do; end
      end
      it 'should not throw an error' do
        GirlFriday.check_for_work
      end
    end
  end

end
