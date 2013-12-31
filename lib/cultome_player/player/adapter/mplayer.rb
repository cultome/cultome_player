module CultomePlayer::Player::Adapter
  module MPlayer
    def play_in_player(song)
      @current_song = song
      player_running? ? loadfile(song) : start_player_with(song)
    end

    def pause_in_player
      toggle_pause
    end

    def resume_in_player
      if paused?
        toggle_pause
        print_in_osd "=====  UNPAUSE  ====="
      else
        play_in_player current_song
      end
    end

    def stop_in_player
      send_to_player "stop"
    end

    def ff_in_player(secs)
      send_to_player "seek #{secs}"
    end

    def fb_in_player(secs)
      send_to_player "seek -#{secs}"
    end

    private

    def check_playback_duration
      send_to_player "get_time_length"
    end

    def check_time_position
      send_to_player "get_time_pos"
    end

    def print_in_osd(msg)
      send_to_player "osd_show_text '#{msg}'"
    end

    def toggle_pause
      send_to_player "pause"
    end

    def loadfile(song, append=false)
      send_to_player "loadfile '#{song.path}' #{append ? 1 : 0}"
    end

    def send_to_player(cmd)
      raise 'invalid state:player is not running' unless player_running?
      control_pipe.puts cmd
      control_pipe.flush
    end

    def control_pipe
      unless pipe_alive?
        @pipe = File.open(mplayer_pipe, 'a+')
      end

      @pipe
    end

    def pipe_alive?
      return !(@pipe.nil? || @pipe.closed?)
    end

    def watch_playback
      Thread.new do
        while pipe_alive?
          check_time_position
          check_playback_duration
          sleep 1
        end
      end
    end

    def start_player_with(song)
      # inicializamos la pipe
      control_pipe
      # cramos el thread que leas del mplayer
      Thread.new do
        start_cmd = "mplayer -slave -input file='#{mplayer_pipe}' '#{song.path}' 2>/dev/null"
        IO.popen(start_cmd).each do |line|
          case line
          when /ANS_TIME_POSITION=([\d.]+)/
            @playback_time_position = $1.to_f
          when /ANS_LENGTH=([\d.]+)/
            @playback_time_length = $1.to_f
          when /=====  PAUSE  =====/
            @stopped = @playing = false
            @paused = true
          when /=====  UNPAUSE  =====/
            @stopped = @paused = false
            @playing = true
          when /Starting playback/
            @is_player_running = @playing = true
            @paused = @stopped = false
            watch_playback
          when /End of file/
            @is_player_running = @playing = @paused = false
            @stopped = true
            control_pipe.close
          end # case
        end # IO
      end # Thread
    end
  end
end
