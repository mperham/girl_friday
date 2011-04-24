# This file is used by Rack-based servers to start the application.

$LOAD_PATH << File.expand_path('../lib')
require 'girl_friday/server'
require ::File.expand_path('../config/environment',  __FILE__)

run Rack::URLMap.new \
  "/"       => Tester::Application,
  "/girl_friday" => GirlFriday::Server.new
