# -*- encoding: utf-8 -*-
require "./lib/girl_friday/version"

Gem::Specification.new do |s|
  s.name        = "girl_friday"
  s.version     = GirlFriday::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mike Perham"]
  s.email       = ["mperham@gmail.com"]
  s.homepage    = "http://github.com/mperham/girl_friday"
  s.summary     = s.description = %q{Background processing, simplified}

  s.rubyforge_project = "girl_friday"

  s.files         = `git ls-files`.split("\n").reject { |path| path =~ /rails_app/}
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency              'connection_pool', '~> 0.9.0'
  s.add_development_dependency  'sinatra', '~> 1.3'
  s.add_development_dependency  'rake'
end
