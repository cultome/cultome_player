module CultomePlayer::Player::Adapter
  module Mpg123

    # Start a playback in the media player.
    #
    # @contract Adapter
    # @param song [Song] The song to be played.
    def play_in_player(song)
      @current_song = song
      unless player_running?
      	start_player
      end

      loadfile(song)
    end

    # Activate the pause in media player.
    #
    # @contract Adapter
    def pause_in_player
      toggle_pause
    end

    # Resume playback in media player. If is paused or stopped.
    #
    # @contract Adapter
    def resume_in_player
      if paused?
        toggle_pause
      else
        play_in_player current_song
      end
    end

    # Stop playback in media player.
    #
    # @contract Adapter
    def stop_in_player
      @user_stopped = true
      send_to_player "stop"
    end

    # Fast forward the playback
    #
    # @contract Adapter
    # @param secs [Integer] Number of seconds to fast forward.
    def ff_in_player(secs)
      send_to_player "jump +#{secs}s"
    end

    # Fast backward the playback
    #
    # @contract Adapter
    # @param secs [Integer] Number of seconds to fast backward.
    def fb_in_player(secs)
      send_to_player "jump -#{secs}s"
    end

    # Turn off the media player
    def quit_in_player
      begin
        send_to_player "quit"
      rescue Exception => e
      end
    end

    # Play from the begining the current playback.
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
                  @user_stopped ?  emit_event(:playback_stopped, current_song) : emit_event(:playback_finish, current_song)
	          		when 1 # paused
			            @stopped = @playing = false
			            @paused = true
                  emit_event(:playback_paused, current_song)
	          		when 2 # unpaused
									@playing = true
	            		@paused = @stopped = false
                  emit_event(:playback_resumed, current_song)
            	end
            when /^@F ([\d]+) ([\d]+) ([\d.]+) ([\d.]+)$/
	            @playback_time_position = $3.to_f
	            @playback_time_length = @playback_time_position + $4.to_f
					end # case line
        end # IO
      end # Thread

      wait_player
    end

    def wait_player
      count = 0
      while !player_running?
        sleep(0.1)
        count += 1
        return if count > 50 # 5 seg
      end
    end

  end
end
