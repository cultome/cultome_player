# inicializamos la gem
require 'cultome/helper'
include Helper

unless Dir.exist?(db_logs_folder_path)
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

	system("mkdir #{db_logs_folder_path}")

	Rake.application.rake_require("tasks/db_admin")
	capture_stdout{Rake.application[:up].invoke}
	#capture_stdout{Rake.application[:down].invoke}
end

require 'java'

require_jars

java_import 'Player'
