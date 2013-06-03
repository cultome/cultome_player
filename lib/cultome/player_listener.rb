require 'player/player_listener'

# Listener to the underlying java music player events.
module Cultome
    module CultomePlayerListener
        include PlayerListener


        # The known states of the underlying music player.
        STATES = {
            -1 =>:UNKNOWN, 
            0 => :OPENING, 
            1 => :OPENED, 
            2 => :PLAYING, 
            3 => :STOPPED, 
            4 => :PAUSED, 
            5 => :RESUMED, 
            6 => :SEEKING, 
            7 => :SEEKED, 
            8 => :EOM, 
            9 => :PAN,
            10 =>:GAIN
        }

        # Callback for progress event. Update the variable @song_status.
        #
        # @param seconds [Integer] The number of seconds transcurred in the current playback
        # @param bytes [Integer] The number of bytes transcurred in the current playback
        def update_progress(seconds, bytes, frame_size)
            @song_status = {seconds: seconds, bytes: bytes, frame_size: frame_size}
        end

        # Callback for stateUpdated event. update the variable @status.
        #
        # @param event [Symbol] A valid state from the hash CultomePlayerListener::STATES
        def update_state(event)
            # si esta reproduciendo..
            # y llega un status de STOPPED y position -1
            # la rola se acabo y pasamos a la siguiente
            if event == :EOM
                return self.execute('next')
            end

            @status = event
        end
    end
end
