Gem::Specification.new do |s|
	s.name = "cultome_player"
	s.version = "0.2.0"
	s.date        = '2013-04-29'
	s.summary     = "CulToMe Player"
	s.description = "A console music library explorer and player"
	s.authors     = ["Carlos Soria"]
	s.email       = "zooria@gmail.com"
	s.files       = Dir['lib/**/*.rb'] + Dir['lib/**/*.rake'] + Dir['bin/*'] + Dir['jars/*.jar'] + Dir['db/**/*']
	s.homepage    = "https://github.com/csoriav/cultome_player"
	s.add_runtime_dependency "activerecord", [">= 3.2.13"]
	s.add_runtime_dependency "activesupport", [">= 3.2.13"]
	s.add_runtime_dependency "mp3info", [">= 0.6.18"]
	s.add_runtime_dependency "activerecord-jdbcsqlite3-adapter", [">= 1.2.9"]
	s.add_runtime_dependency "rb-readline", [">= 0.4.2"]
	s.add_runtime_dependency "htmlentities", [">= 4.3.1"]
	s.add_runtime_dependency "json", [">= 1.7.7"]

	s.executables << 'cultome_player'
end
