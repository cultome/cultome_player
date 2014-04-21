module CultomePlayer::Player::Adapter
  module Mpg123
    # Contract
    def play_in_player(song)
      @current_song = song
      unless player_running?
      	start_player
      end

      loadfile(song)
    end

    # Contract
    def pause_in_player
      toggle_pause
    end

    # Contract
    def resume_in_player
      if paused?
        toggle_pause
      else
        play_in_player current_song
      end
    end

    # Contract
    def stop_in_player
      send_to_player "stop"
    end

    # Contract
    def ff_in_player(secs)
      send_to_player "jump +#{secs}s"
    end

    # Contract
    def fb_in_player(secs)
      send_to_player "jump -#{secs}s"
    end

    def quit_in_player
      send_to_player "quit"
    end

    def repeat_in_player
      send_to_player "jump 0"
    end

    private

    def toggle_pause
      send_to_player "pause"
    end

    def loadfile(song)
      send_to_player "load #{song.path}"
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

    def start_player
      # creamos el thread que lea la salida del mpg123
      Thread.new do
        start_cmd = "mpg123 --fifo #{mplayer_pipe} -R"
        IO.popen(start_cmd).each do |line|
          case line
          	when /^@R MPG123/
      				@is_player_running = true
          	when /^@P ([\d])$/
          		case $1.to_i
	          		when 0 # stopped
	          			@playing = @paused = false
	            		@stopped = true
	          		when 1 # paused
			            @stopped = @playing = false
			            @paused = true
	          		when 2 # unpaused
									@playing = true
	            		@paused = @stopped = false
            	end
            when /^@F ([\d]+) ([\d]+) ([\d.]+) ([\d.]+)$/
	            @playback_time_position = $3.to_f
	            @playback_time_length = @playback_time_position + $4.to_f
					end # case line
        end # IO
      end # Thread
    end
  end
end