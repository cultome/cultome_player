require 'coveralls'

Coveralls.wear!

require 'cultome_player'
require 'cultome_player/helper'
require 'active_record'

include CultomePlayer::Helper

RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.run_all_when_everything_filtered = true
    config.filter_run :focus
    config.filter_run_excluding :resources
    config.order = 'random'

    config.around :each do |example|
        with_connection &example
    end
end

class MockMusicPlayer
    def initialize(player_status_holder)
        @status = player_status_holder
    end

    def play(path)
        @status.state = :PLAYING
        @status.song_status = {seconds: 10, bytes: 1000, frame_size: 100}
    end

    def seek(next_pos)
        @status.song_status = {seconds: next_pos > 0 ? 35 : 9, bytes: next_pos, frame_size: 100}
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

class MockSocket
    def buffer=(buffer)
        @buffer = buffer
    end

    def recv(size)
        @buffer
    end

    def print(msg)
    end
end

class TestOutput
    def print(msg)
    end

    def puts(msg)
    end
end

class Test
    include CultomePlayer

    def initialize
        set_environment({
            user_dir: "#{project_path}/spec/data/user"
        })
        @mock_player = MockMusicPlayer.new(player)
    end

    def player_output
        TestOutput.new
    end

    16.times do |idx|
        define_method "c#{idx}" do |str|
            return str
        end
    end

    def play_in_local_player(path)
        @mock_player.play(path)
    end

    def seek_in_local_player(next_pos)
        @mock_player.seek(next_pos)
    end

    def pause_in_local_player
        @mock_player.pause
    end

    def resume_in_local_player
        @mock_player.resume
    end

    def stop_in_local_player
        @mock_player.stop
    end
end

class ActiveRecord::Base

    16.times do |idx|
        define_method "c#{idx}" do |str|
            return str
        end
    end

end


ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: "#{project_path}/spec/data/user/db_cultome.dat")
