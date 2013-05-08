# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cultome/version'

Gem::Specification.new do |gem|
	gem.name          = "cultome_player"
	gem.version       = CultomePlayer::VERSION
	gem.date          = '2013-05-04'
	gem.summary       = "CulToMe Player"
	gem.description   = "A console music library explorer and player"
	gem.authors       = ["Carlos Soria"]
	gem.email         = "zooria@gmail.com"
	gem.homepage      = "https://github.com/csoriav/cultome_player"

	gem.files         = `git ls-files`.split($/)
	gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
	gem.require_paths = ["lib"]

	gem.add_runtime_dependency "activerecord", [">= 3.2.13"]
	gem.add_runtime_dependency "activesupport", [">= 3.2.13"]
	gem.add_runtime_dependency "mp3info", [">= 0.6.18"]
	gem.add_runtime_dependency "activerecord-jdbcsqlite3-adapter", [">= 1.2.9"]
	gem.add_runtime_dependency "rb-readline", [">= 0.4.2"]
	gem.add_runtime_dependency "htmlentities", [">= 4.3.1"]
	gem.add_runtime_dependency "json", [">= 1.7.7"]
	gem.add_runtime_dependency "share_this", [">= 0.1.0"]
end
