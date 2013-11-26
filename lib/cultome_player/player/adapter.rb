require 'cultome_player/player/adapter/mplayer'

module CultomePlayer::Player::Adapter
  include MPlayer

  def player_running?
    @is_player_running
  end

end

