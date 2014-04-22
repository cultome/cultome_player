require 'cultome_player'
require 'pry'

include CultomePlayer::Environment

desc "Start a interactive session in the player"
task :console do
  include CultomePlayer::Objects
  
  p = CultomePlayer.get_player

  ActiveRecord::Base.establish_connection(
    adapter: db_adapter,
    database: db_file
  )
  ActiveRecord::Base.logger = Logger.new(File.open(db_log_file, 'a'))

  binding.pry
end
