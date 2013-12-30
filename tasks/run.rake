desc "Execute the player in interactive mode in user env"
task :run do
  $LOAD_PATH << File.join(File.dirname(File.expand_path(__FILE__)), "..")
  require 'cultome_player'
  player = CultomePlayer.get_player(:user)
  player.begin_session
end
