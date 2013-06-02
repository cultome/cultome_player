require 'cultome/core'

module Cultome

    require player_implementation

    class CultomePlayer
        include CultomePlayerCore

        attr_accessor :playlist
        attr_accessor :search_results
        attr_accessor :history
        attr_accessor :queue
        attr_accessor :focus
        attr_accessor :drives
        attr_accessor :prompt

        attr_accessor :song
        attr_accessor :prev_song
        attr_accessor :artist
        attr_accessor :album
        attr_accessor :running
        attr_accessor :play_index
        attr_accessor :is_playing_library
        attr_accessor :is_shuffling
        attr_accessor :last_cmds
        attr_accessor :current_command

        attr_reader :player
        attr_reader :status
        attr_reader :song_status

        def initialize
            @player = Player.new(self)
            @search_results= []
            @playlist = []
            @history = []
            @queue = []
            @play_index = -1
            @status = :STOPPED
            @song_status = {}
            @last_cmds = []
            @is_shuffling = true
            @is_playing_library = false
            @prompt = master_config['core']['prompt']
        end
    end
end

