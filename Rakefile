require 'active_record'
require 'logger'
require 'yaml'

task :default => :migrate

desc "Migrate the database through scripts in db/migrate."

task :up => :establish_connection do
	ActiveRecord::Migrator.migrate('./db/migrate')
end

task :down => :establish_connection do
	ActiveRecord::Migrator.rollback('db/migrate')
end

task :reset => :establish_connection do
	ActiveRecord::Migrator.rollback('db/migrate')
	ActiveRecord::Migrator.migrate('db/migrate')
end

task :establish_connection do
	ActiveRecord::Base.establish_connection(YAML::load(File.open('database.yml')))
	ActiveRecord::Base.logger = Logger.new(File.open('logs/db.log', 'a'))
end
