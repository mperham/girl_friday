require 'helper'


class TestErrorHandler < MiniTest::Unit::TestCase
  Stderr = GirlFriday::ErrorHandler::Stderr
  Airbrake = GirlFriday::ErrorHandler::Airbrake

  class FakeStderr
    include Faker
    def flush
      "WOOSH!"
    end
    alias_method :puts, :count
    alias_method :write, :count
  end

  class FakeAirbrake
    include Faker
    alias_method :notify_or_ignore, :count
  end

  class FakeError
    def backtrace
     %w(
      We're no strangers to love
      You know the rules and so do I
      A full commitment's what I'm thinking of
      You wouldn't get this from any other guy
      I just wanna tell you how I'm feeling
      Gotta make you understand
     )
    end
  end

  def handler
    GirlFriday::ErrorHandler
  end

  def test_default
    assert_equal [Stderr], handler.default

    Object.const_set("Airbrake","super cool error catcher")
    assert_equal [Stderr,Airbrake], handler.default
    Object.send(:remove_const,:Airbrake)
  end

  def test_stderr
    $stderr = FakeStderr.new
    Stderr.new.handle(FakeError.new)
    assert_equal 2, $stderr.number_of_calls
  end

  def test_airbrake
    airbrake = FakeAirbrake.new
    Object.const_set("Airbrake", airbrake)
    Airbrake.new.handle(FakeError.new)
    assert_equal 1, airbrake.number_of_calls
    Object.send(:remove_const,:Airbrake)
  end
end
