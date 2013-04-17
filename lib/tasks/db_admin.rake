require 'cultome/helper'
require 'active_record'
require 'logger'

task :default => :migrate

desc "Migrate the database through scripts in db/migrate."

task :up => :establish_connection do
	ActiveRecord::Migrator.migrate(migrations_path)
end

task :down => :establish_connection do
	ActiveRecord::Migrator.rollback(migrations_path)
end

task :reset => :establish_connection do
	ActiveRecord::Migrator.rollback(migrations_path)
	ActiveRecord::Migrator.migrate(migrations_path)
end

task :establish_connection do
	ActiveRecord::Base.establish_connection(
		adapter: db_adapter,
		database: db_file
	)
	ActiveRecord::Base.logger = Logger.new(File.open(db_log_path, 'a'))
end
