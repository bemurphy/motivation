# -*- encoding: utf-8 -*-
require File.expand_path('../lib/motivation/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Brendon Murphy"]
  gem.email         = ["xternal1+github@gmail.com"]
  gem.summary       = %q{Simple DSL for use in classes to motivate a user towards a goal}
  gem.description   = gem.summary
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "motivation"
  gem.require_paths = ["lib"]
  gem.version       = Motivation::VERSION

  gem.add_development_dependency "rspec", "~> 2.13.0"
end
