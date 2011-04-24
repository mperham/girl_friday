class MessagesController < ApplicationController
  def index
    10.times do |idx|
      TEST_QUEUE << idx
    end
    render :nothing => true
  end
end
