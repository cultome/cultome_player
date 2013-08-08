# encoding: utf-8
module CultomePlayer
  module ErrorHandler

    # Register a callaback into the playback_fail event.
    #
    # @param base [Class] The class in which this module was included.
    def self.included(base)
      CultomePlayer::Player.register_event_listener(:playback_fail, :playback_error_handler)
    end

    # Callback to be called when playback_fail event is fired. Basicly show a message with the error and execute a #next action.
    #
    # @param error_msg [String] The error descripcion sended by the player.
    def playback_error_handler(error_msg)
      begin
        system("mplayer '#{current_song.path}'")
      rescue
        display_with_prompt c2("Could not play #{current_song}")
        r = execute('next').first
        display_with_prompt r
      end
    end
  end
end
