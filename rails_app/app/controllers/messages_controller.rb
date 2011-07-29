class MessagesController < ApplicationController
  def index
    30.times do |idx|
      TEST_QUEUE << idx
    end

    10.times do |idx|
      SOME_QUEUE << idx
    end
    render :nothing => true
  end
end
