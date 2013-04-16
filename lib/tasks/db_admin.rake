require 'active_record'
require 'logger'
require 'yaml'

task :default => :migrate
base_dir = File.expand_path(File.dirname(__FILE__) + "../../..")
migrations_base = "#{base_dir}/db/migrate"

desc "Migrate the database through scripts in db/migrate."

task :up => :establish_connection do
	ActiveRecord::Migrator.migrate(migrations_base)
end

task :down => :establish_connection do
	ActiveRecord::Migrator.rollback(migrations_base)
end

task :reset => :establish_connection do
	ActiveRecord::Migrator.rollback(migrations_base)
	ActiveRecord::Migrator.migrate(migrations_base)
end

task :establish_connection do
	ActiveRecord::Base.establish_connection(YAML::load(File.open("#{base_dir}/database.yml")))
	ActiveRecord::Base.logger = Logger.new(File.open("#{base_dir}/logs/db.log", 'a'))
end
