require 'cultome_player/player/adapter/mpg123'

module CultomePlayer::Player::Adapter
  include Mpg123

  def player_running?
    @is_player_running
  end

end

