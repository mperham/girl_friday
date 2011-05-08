EMAIL_QUEUE = GirlFriday::WorkQueue.new(:user_email, :size => 3) do |msg|
    UserMailer.registration_email(msg).deliver
end
IMAGE_QUEUE = GirlFriday::WorkQueue.new(:image_crawler, :size => 7) do |msg|
    ImageCrawler.process(msg)
end
