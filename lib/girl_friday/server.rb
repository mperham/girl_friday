require 'sinatra/base'
require 'erb'
require 'girl_friday'

# QUEUE1 = GirlFriday::Queue.new('ham_cannon', :size => 15) do |msg|
#   puts msg
# end
# QUEUE2 = GirlFriday::Queue.new('image_crawler', :size => 5) do |msg|
#   puts msg
# end

module GirlFriday
  class Server < Sinatra::Base
    basedir = File.expand_path(File.dirname(__FILE__) + '/../../server')

    set :views,  "#{basedir}/views"
    set :public, "#{basedir}/public"
    set :static, true
    
    helpers do
      include Rack::Utils
      alias_method :h, :escape_html
    end
    
    get '/' do
      @status = GirlFriday.status
      erb :index
    end
  end
end