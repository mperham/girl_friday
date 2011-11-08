require 'girl_friday'
require 'open-uri'
require 'benchmark'
require 'nokogiri'

class UrlProcessor
  URLS = %w(http://www.bing.com http://www.google.com http://www.yahoo.com)

  def parallel
    batch = GirlFriday::Batch.new(nil, :size => 3) do |url|
      html = open(url)
      doc = Nokogiri::HTML(html.read)
      doc.css('span').count
    end
    URLS.each do |url|
      batch << url
    end
    p URLS.zip(batch.results)
  end

  def serial
    results = URLS.map do |url|
      html = open(url)
      doc = Nokogiri::HTML(html.read)
      doc.css('span').count
    end
    p URLS.zip(results)
  end
end

# Expected output:
# [["http://www.bing.com", 24], ["http://www.google.com", 8], ["http://www.yahoo.com", 172]]
#
# Benchmark results:
# serial                   1.231000   0.000000   1.231000 (  1.231000)
# parallel                 0.447000   0.000000   0.447000 (  0.447000)

processor = UrlProcessor.new
Benchmark.bm(25) do |x|
  %w(serial parallel).each do |op|
    x.report(op) do
      processor.send(op.to_sym)
    end
  end
end
