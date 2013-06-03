class Player
    def initialize(player)
        @player = player

        player.class_eval do
            def status=(value)
                @status = value
            end
            def set_song_status(seconds, bytes, frame)
                update_progress(seconds, bytes, frame)
            end
        end
    end

    def play(song)
        @player.status = :PLAYING
        @player.set_song_status(45, 1000, 250)
        song
    end

    def resume
        @player.status = :RESUMED
    end

    def pause
        @player.status = :PAUSED
    end

    def stop
        @player.status = :STOPPED
    end

    def seek(next_pos)
        @player.set_song_status(45, next_pos, 250)
    end
end
