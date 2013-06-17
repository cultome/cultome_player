
module CultomePlayer::Player
    class PlayerStateHolder
        attr_accessor :playlist
        attr_accessor :focus
        attr_accessor :search_results
        attr_accessor :queue
        attr_accessor :history

        attr_accessor :song
        attr_accessor :artist
        attr_accessor :album
        attr_accessor :prev_song
        attr_accessor :current_command

        attr_accessor :play_index
        attr_accessor :current_prompt

        attr_accessor :state
        attr_accessor :song_status
        attr_accessor :playing_library
        attr_accessor :shuffling

        alias :playing_library? :playing_library
        alias :shuffling? :shuffling

        alias :songs_in_playlist :playlist
        alias :songs_in_focus :focus
        alias :songs_in_search_results :search_results
        alias :songs_in_search :search_results
        alias :songs_in_queue :queue
        alias :songs_in_history :history

        def initialize
            @playlist = []
            @focus = []
            @search_results = []
            @queue = []
            @history = []

            @song = nil
            @artist = nil
            @album = nil
            @prev_song = nil
            @current_command = nil

            @play_index = 0
            @current_prompt = 'cultome> '

            @song_status = {seconds: 0, bytes: 0, frame_size: 0}
            @state = :STOPPED
            @shuffling = true
            @playing_library = false
        end

        # Lazy initializator for drives.
        #
        # @return [List<Drive>] The list of drives registered in the player.
        def drives
			@drives ||= CultomePlayer::Model::Drive.all.to_a
        end
    end
end
