# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cultome_player/version'

Gem::Specification.new do |gem|
  gem.name          = "cultome_player"
  gem.version       = CultomePlayer::VERSION
  gem.summary       = "CulToMe Player"
  gem.description   = "A console music library explorer and player"
  gem.authors       = ["Carlos Soria"]
  gem.email         = "zooria@gmail.com"
  gem.homepage      = "https://github.com/csoriav/cultome_player"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "activerecord", "~> 4.0.0"
  gem.add_runtime_dependency "activesupport", "~> 4.0.0"
  gem.add_runtime_dependency "taglib-ruby", "~> 0.6.0"
  gem.add_runtime_dependency "rb-readline", "~> 0.4.2"
  gem.add_runtime_dependency "sqlite3", "~> 1.3.7"
  gem.add_runtime_dependency "colorize", "~> 0.5.8"

  gem.add_development_dependency "rake", "~> 10.0.4"
  gem.add_development_dependency "coveralls", "~> 0.6.7"
  gem.add_development_dependency "rspec", "~> 2.13.0"
  gem.add_development_dependency "bundler", "~> 1.3"
  gem.add_development_dependency "database_cleaner", "~> 1.2.0"
end
