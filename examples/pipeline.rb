require 'open-uri'
require 'nokogiri'
require 'girl_friday'


##
# In this example, we use girl_friday to implement a processing pipeline
# for scraping large images from a website.  Given a URL, we want to fetch
# the HTML for that URL, find all the images, download those images, discard images
# which do not meet a size heuristic and save the ones that match.  This
# processing is I/O-heavy and perfect for breaking into many threads.
#
# A processing pipeline is just a series of linked processing steps.
# We create a girl_friday queue for each step, sized appropriately for how few/many parallel worker threads we want for that step.
# The process_xxx methods implement the actual logic for the step.
# The finish_xxx methods pass the result to the next step in the pipeline.
#
class ImagePipeline
  def initialize
    @download_html = GirlFriday::Queue.new(:download_html, :size => 5, &method(:process_html))
    @extract_imgs = GirlFriday::Queue.new(:extract, :size => 2, &method(:process_extract))
    @download_imgs = GirlFriday::Queue.new(:download_imgs, :size => 10, &method(:process_imgs))
    @thumb = GirlFriday::Queue.new(:thumb_imgs, :size => 5, &method(:process_thumb))
  end

  def process(url)
    log "Pushing #{url}"
    @download_html.push({ :url => url }, &method(:finish_html))
  end

  private

  def process_html(msg)
    msg.merge(:htmlfile => open(msg[:url]))
  end

  def finish_html(result)
    @extract_imgs.push(result, &method(:finish_extract))
  end

  def process_extract(msg)
    doc = Nokogiri::HTML(msg[:htmlfile].read)
    doc.css('img[src]').map{|n| n['src']}.select { |url| url =~ /^#{msg[:url]}/ }
  end

  def finish_extract(result)
    result.each do |imgurl|
      @download_imgs.push(imgurl, &method(:finish_imgs))
    end
  end

  def process_imgs(msg)
    log "Fetching image: #{msg}"
    imgfile = open msg
    return if imgfile.size < 20_000 # ignore images less than 20k
    result = `identify #{imgfile.path}`
    log "Image: #{result}"
    return unless result =~ /(\d+)x(\d+)\+0\+0/
    return if Integer($1) + Integer($2) < 500
    # Passed all our heuristics, pass it on!
    imgfile
  end

  def finish_imgs(result)
    return unless result
    @thumb.push(result, &method(:finish_thumb))
  end

  def process_thumb(msg)
    FileUtils.cp msg.path, Time.now.to_f.to_s
    msg.path
  end

  def finish_thumb(result)
    log "Finished image at #{result}"
  end

  def log(msg)
    print "#{Thread.current}: #{msg}\n"
  end
end


pipeline = ImagePipeline.new
pipeline.process 'http://blog.carbonfive.com'

loop do
  sleep 1
end
