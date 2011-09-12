# -*- encoding: utf-8 -*-
require File.expand_path('../lib/guidestar_client/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nat Budin"]
  gem.email         = ["natbudin@gmail.com"]
  gem.description   = %q{Client for GuideStar charity search API}
  gem.summary       = %q{GuideStar charity search client}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "guidestar_client"
  gem.require_paths = ["lib"]
  gem.version       = GuidestarClient::VERSION

  gem.add_dependency "savon"
  gem.add_development_dependency "rspec", "~> 2.6.0"
  gem.add_development_dependency "rack", "~> 1.3.0"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "simplecov-rcov"
  gem.add_development_dependency "webmock", "~> 1.7.0"
  gem.add_development_dependency "i18n"
  gem.add_development_dependency "activesupport", "~> 3.0.10"
end
