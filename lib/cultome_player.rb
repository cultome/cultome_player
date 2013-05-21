# inicializamos la gem
require 'cultome/helper'
include Helper

unless Dir.exist?(db_logs_folder_path)
	puts "Running for the first time. Preparing environment..."

	require 'rake'
	require 'fileutils'

	def capture_stdout
		s = StringIO.new
		oldstd = $stdout
		$stdout = s
		yield
		s.string
	ensure
		$stdout = oldstd
	end

	# creamos los archivo necesarios
	FileUtils.mkpath(db_logs_folder_path)
	FileUtils.mkpath(user_dir) unless File.exist?(user_dir)
	unless File.exist?(config_file)
		FileUtils.cp(File.join(project_path, CONFIG_FILE_NAME), config_file)
	end

	Rake.application.rake_require("tasks/db_admin")


	#capture_stdout{Rake.application[:down].invoke}
	capture_stdout{Rake.application[:up].invoke}
end

require 'java'

require_jars

java_import 'Player'
