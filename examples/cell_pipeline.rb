require 'open-uri'
require 'nokogiri'
require 'celluloid'

class ImagePipeline
  include Celluloid

  def process(url)
    scrape_page!(url)
  end

  def scrape_page(url)
    result = open url
    extract! url, result
  end

  def extract(url, io)
    doc = Nokogiri::HTML(io.read)
    images = doc.css('img[src]').map{|n| n['src']}.select { |url| url =~ /^#{url}/ }
    images.each do |imgurl|
      download_image! imgurl
    end
  end

  def download_image(imgurl)
    log "Fetching image: #{imgurl}"
    imgfile = open imgurl
    return if imgfile.size < 20_000 # ignore images less than 20k
    result = `identify #{imgfile.path}`
    log "Image: #{result}"
    return unless result =~ /(\d+)x(\d+)\+0\+0/
    return if Integer($1) + Integer($2) < 500
    # Passed all our heuristics, pass it on!
    thumb! imgfile
  end

  def thumb(file)
    FileUtils.cp file.path, Time.now.to_f.to_s
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
