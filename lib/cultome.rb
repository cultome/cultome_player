# inicializamos la gem

base_path = File.expand_path(File.dirname(__FILE__) + "/..")

unless Dir.exist?("#{ base_path }/logs")
	puts "Running for the first time. Preparing environment..."

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

	system("mkdir #{base_path}/logs")

	Rake.application.rake_require("tasks/db_admin")
	capture_stdout{Rake.application[:up].invoke}
	#capture_stdout{Rake.application[:down].invoke}
end

require 'cultome/helper'
require 'java'

include Helper

require_jars

java_import 'Player'
