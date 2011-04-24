#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
require 'girl_friday/server'

use Rack::ShowExceptions
run GirlFriday::Server.new