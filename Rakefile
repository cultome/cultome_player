require 'active_record'
require 'logger'
require 'yaml'

task :default => :migrate

desc "Migrate the database through scripts in db/migrate. Target specific version with VERSION=x"
task :migrate => :environment do
  ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : 1 )
end

task :rollback => :environment do
  ActiveRecord::Migrator.rollback('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : 1 )
end

task :reset => :environment do
  ActiveRecord::Migrator.rollback('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : 1 )
  ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : 1 )
end

task :environment do
  ActiveRecord::Base.establish_connection(YAML::load(File.open('database.yml')))
  ActiveRecord::Base.logger = Logger.new(File.open('logs/db.log', 'a'))
end
