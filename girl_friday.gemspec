# -*- encoding: utf-8 -*-
require "./lib/girl_friday/version"

Gem::Specification.new do |spec|
  spec.name          = "girl_friday"
  spec.version       = GirlFriday::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Mike Perham"]
  spec.email         = ["mperham@gmail.com"]
  spec.homepage      = "https://github.com/mperham/girl_friday"
  spec.summary       = spec.description = %q{Background processing, simplified}
  spec.files         = `git ls-files`.split("\n").reject { |path| path =~ /rails_app/}
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency             'connection_pool', '~> 1.0'
  spec.add_dependency             'rubinius-actor'
  spec.add_development_dependency 'sinatra', '~> 1.3'
  spec.add_development_dependency 'rake'
end
