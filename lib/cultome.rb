
# inicializamos la gem
begin
	require 'persistence'
	Song.first
rescue Exception => e
	print "Running for the first time. Preparing environment..."

	require 'rake'

	def capture_stdout
		s = StringIO.new
		oldstd = $stdout
		$stdout = s
		yield
		s.string
	ensure
		$stdout = oldstd
	end

	system("mkdir logs")

	Rake.application.init
	Rake.application.load_rakefile
	capture_stdout{Rake.application[:up].invoke}
	#capture_stdout{Rake.application[:down].invoke}
end

require 'helper'
require 'java'

include Helper

require_jars

java_import 'Player'
