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
    set :public_folder, "#{basedir}/public"
    set :static, true

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html

      def url_path(*path_parts)
        [path_prefix, path_parts].join('/').squeeze('/')
      end
      alias_method :u, :url_path

      def path_prefix
        request.env['SCRIPT_NAME']
      end
    end

    get '/?' do
      redirect url_path('status')
    end

    get '/status' do
      @status = GirlFriday.status
      erb :index
    end

    get '/status.json' do
      content_type :json
      GirlFriday.status.to_json
    end
  end
end
