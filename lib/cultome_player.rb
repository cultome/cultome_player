# inicializamos la gem
require 'cultome/helper'
require 'fileutils'

include Helper

def capture_stdout
	s = StringIO.new
	oldstd = $stdout
	$stdout = s
	yield
	s.string
ensure
	$stdout = oldstd
end

def check_directories_integrity
	FileUtils.mkpath(db_logs_folder_path) unless Dir.exist?(db_logs_folder_path)
	FileUtils.mkpath(user_dir) unless File.exist?(user_dir)
end

def check_config_files_integrity
	FileUtils.cp(File.join(project_path, CONFIG_FILE_NAME), config_file) unless File.exist?(config_file)
end

def check_database_integrity
	with_connection do
		max_version = ActiveRecord::Migrator.migrations(migrations_path).max{|m| m.version }.version
		current_version = ActiveRecord::Migrator.current_version

		if max_version > current_version
			capture_stdout { ActiveRecord::Migrator.migrate(migrations_path) }
		end
	end
end

check_directories_integrity
check_config_files_integrity
check_database_integrity

require 'java'

require_jars

java_import 'Player'
