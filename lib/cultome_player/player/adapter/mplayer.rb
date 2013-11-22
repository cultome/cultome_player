module CultomePlayer::Player::Adapter
  module MPlayer
    def play_in_player(song)
      @paused = @stopped = false
      @playing = true
      @current_song = song
    end

    def pause_in_player
      @stopped = @playing = false
      @paused = true
    end

    def resume_in_player
      @stopped = @paused = false
      @playing = true
    end

    def stop_in_player
      @playing = @paused = false
      @stopped = true
    end
  end
end
