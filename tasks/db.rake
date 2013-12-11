require 'cultome_player/environment'

include CultomePlayer::Environment
include CultomePlayer::Utils
include CultomePlayer::Objects

namespace :db do
  desc "Create database schema"
  task :create, :env do |t, args|
    migrations_path= File.join(File.dirname(File.expand_path(__FILE__)), "../db")
    env = args[:env] || :user
    prepare_environment(env, false)
    with_connection do
      ActiveRecord::Migrator.migrate(migrations_path)
      Album.find_or_create_by(id: 0, name: 'Unknown')
      Artist.find_or_create_by(id: 0, name: 'Unknown')
    end
  end
end
