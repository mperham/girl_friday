# -*- encoding: utf-8 -*-
require "./lib/girl_friday/version"

Gem::Specification.new do |s|
  s.name        = "girl_friday"
  s.version     = GirlFriday::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mike Perham"]
  s.email       = ["mperham@gmail.com"]
  s.homepage    = ""
  s.summary     = s.description = %q{Background processing via Rubinius's actor API}

  s.rubyforge_project = "girl_friday"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
