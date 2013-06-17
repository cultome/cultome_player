
module CultomePlayer
    class GenericMusicPlayer
        def initialize(player_status_holder)
            @status = player_status_holder
        end

        def play(path)
            @status.state = :PLAYING
            @status.song_status = {seconds: 10, bytes: 1000, frame_size: 125}
        end

        def seek(next_pos)
            @status.song_status = {seconds: next_pos, bytes: next_pos, frame_size: 100}
        end

        def pause
            @status.state = :PAUSED
        end

        def resume
            @status.state = :RESUMED
        end

        def stop
            @status.state = :STOPPED
        end
    end
end
