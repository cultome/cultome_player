# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cultome_player/version'
# select the faile that goes inside the gem
git_index = `git ls-files`.split("\n")
gitignored = `cat .gitignore`.split("\n")
excluded = `cat .excluded`.split("\n")

files = git_index.select{|filepath| !gitignored.include?(filepath) }
                 .select{|filepath| excluded.none?{|excl_regex| filepath =~ /#{excl_regex}/ }}

Gem::Specification.new do |gem|
  gem.name          = "cultome_player"
  gem.version       = CultomePlayer::VERSION
  gem.summary       = "CulToMe Player"
  gem.description   = "A console music library explorer and player"
  gem.author        = "Carlos Soria"
  gem.email         = "cultome@protonmail.com"
  gem.homepage      = "https://github.com/cultome/cultome_player"
  gem.license       = "MIT"

  gem.files         = files
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "activerecord", "~> 5.0"
  gem.add_runtime_dependency "activesupport", "~> 5.0"
  gem.add_runtime_dependency "taglib-ruby", "~> 0.7"
  gem.add_runtime_dependency "rb-readline", "~> 0.5"
  gem.add_runtime_dependency "sqlite3", "~> 1.3"
  gem.add_runtime_dependency "colorize", "~> 0.8"

  gem.add_development_dependency "rake", "~> 11.2"
  gem.add_development_dependency "coveralls", "~> 0.8"
  gem.add_development_dependency "rspec", "~> 3.5"
  gem.add_development_dependency "bundler", "~> 1.12"
  gem.add_development_dependency "database_cleaner", "~> 1.5"
  gem.add_development_dependency "pry", "~> 0.10"
  gem.add_development_dependency "yard", "~> 0.9"
end
