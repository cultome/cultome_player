require 'cultome_player/environment'

include CultomePlayer::Environment

namespace :db do
  desc "Create database schema"
  task :create do
    migrations_path= File.join(File.dirname(File.expand_path(__FILE__)), "../db")
    with_connection do
      ActiveRecord::Migrator.migrate(migrations_path)
    end
  end
end
