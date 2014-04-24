require 'cultome_player/player/adapter/mpg123'

module CultomePlayer::Player::Adapter
  include Mpg123

  # Check if media player is running.
  #
  # @return [Boolean] True is player is running. False otherwise.
  def player_running?
    @is_player_running
  end

end

