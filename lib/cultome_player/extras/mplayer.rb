# encoding: utf-8
module CultomePlayer::Extras
  module MPlayer
    extend CultomePlayer::Helper

    SEEK_STEP_IN_SEC = 15
    PIPE = "#{user_dir}/mplayercontrol"


    def self.included(base)
      CultomePlayer::Player.register_event_listener(:quitting, :quit_mplayer)
    end

    def play_in_local_player(path)
      if mplayer_is_alive?
        send_command_to_mplayer("loadfile '#{path}'")
      else
        launch_mplayer(path)
      end

      # resteamos el contador de segundos
      @song_counter = 0
      # actualizamos el status
      player.state = CultomePlayer::ExternalPlayer::EXTERNAL_PLAYER_STATES[2]
    end

    def seek_in_local_player(next_pos)
      raise "Should not invoke this method!"
    end

    def pause_in_local_player
      send_command_to_mplayer("pause")
      player.state = CultomePlayer::ExternalPlayer::EXTERNAL_PLAYER_STATES[4]
    end

    def resume_in_local_player
      send_command_to_mplayer("pause")
      player.state = CultomePlayer::ExternalPlayer::EXTERNAL_PLAYER_STATES[5]
    end

    def stop_in_local_player
      send_command_to_mplayer("stop")
      player.state = CultomePlayer::ExternalPlayer::EXTERNAL_PLAYER_STATES[3]
    end

    def quit_mplayer
      send_command_to_mplayer("quit") if mplayer_is_alive?
      @time_thread.kill unless @time_thread.nil?
      @pipe.close
    end

    # Some cables must be twisted because in this moment i dont want to catch the
    # mplayer output and parse it to extract the progress of the current playback
    def ff(params=[])
      if mplayer_is_alive?
        send_command_to_mplayer("seek #{SEEK_STEP_IN_SEC}")
        @song_counter += SEEK_STEP_IN_SEC
      end
    end

    def fb(params=[])
      if mplayer_is_alive?
        send_command_to_mplayer("seek -#{SEEK_STEP_IN_SEC}")
        @song_counter -= SEEK_STEP_IN_SEC
      end
    end

    def song_progress
      @song_counter
    end

    private

    def mplayer_is_alive?
      !@mplayer_thread.nil? && @mplayer_thread.alive?
    end

    def send_command_to_mplayer(command)
      return nil unless mplayer_is_alive?
      @pipe.puts command
      @pipe.flush
    end

    def launch_mplayer(song_path)
      @pipe ||= File.open(PIPE, 'a+')

      @mplayer_thread = Thread.new do
        swallow_stdout do
          system("mplayer -slave -quiet -input file='#{PIPE}' '#{song_path}' 2>/dev/null > /dev/null")
        end
      end
      playback_clock
    end

    def playback_clock
      @time_thread ||= Thread.new do
        while true
          sleep(1)
          @song_counter += 1 unless paused?
        end
      end
    end
  end
end
