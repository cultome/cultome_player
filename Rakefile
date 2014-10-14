require "bundler/gem_tasks"
require 'cultome_player'

desc "Execute the player in interactive mode in user env"
task :run => :environment do
  player = CultomePlayer.get_player(current_env)
  player.begin_session
end

desc "Create database schema"
task :reset => :environment do
  include CultomePlayer::Utils
  recreate_db_schema
end

desc "Start a interactive session in the player"
task :console => :environment do
  require 'irb'
  require 'irb/completion'

  p = CultomePlayer.get_player(current_env)

  ActiveRecord::Base.establish_connection({
    adapter: db_adapter,
    database: db_file
  })
  ActiveRecord::Base.logger = Logger.new(File.open(db_log_file, 'a'))

  include CultomePlayer
  include CultomePlayer::Environment

  ARGV.clear
  IRB.start
end

task :environment do |t, args|
  include CultomePlayer::Environment

  env = ENV["ENV"] || :user
  prepare_environment(env)
  puts "Using #{env} environment."
end
