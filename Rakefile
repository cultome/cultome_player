require "bundler/gem_tasks"

desc "Execute the player in interactive mode in user env"
task :run do
  $LOAD_PATH << File.join(File.dirname(File.expand_path(__FILE__)), "..")
  require 'cultome_player'
  player = CultomePlayer.get_player(:user)
  player.begin_session
end

desc "Create database schema"
task :reset, :env do |t, args|
  require 'cultome_player'

  include CultomePlayer::Environment
  include CultomePlayer::Utils
  include CultomePlayer::Objects

  migrations_path= File.join(File.dirname(File.expand_path(__FILE__)), "../db")
  env = args[:env] || :user
  prepare_environment(env)
  recreate_db_schema
  with_connection do
    ActiveRecord::Migrator.migrate(migrations_path)
    Album.find_or_create_by(id: 0, name: 'Unknown')
    Artist.find_or_create_by(id: 0, name: 'Unknown')
  end
end

desc "Start a interactive session in the player"
task :console do
  require 'cultome_player'
  require 'irb'
  require 'irb/completion'

  include CultomePlayer::Objects
  include CultomePlayer::Environment

  p = CultomePlayer.get_player

  ActiveRecord::Base.establish_connection(
    adapter: db_adapter,
    database: db_file
  )
  ActiveRecord::Base.logger = Logger.new(File.open(db_log_file, 'a'))

  ARGV.clear
  IRB.start
end
