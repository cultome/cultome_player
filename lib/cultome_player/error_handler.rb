
module CultomePlayer
    module ErrorHandler
        def self.included(base)
            CultomePlayer::Player.register_event_listener(:playback_fail, :playback_error_handler)
        end

        def playback_error_handler(error_msg)
            display_with_prompt c2("Could not play #{current_song}")
            r = execute('next').first
            display_with_prompt r
        end
    end
end
