require 'cultome_player/extras/command_alias'
require 'cultome_player/extras/copy_to'
require "cultome_player/extras/colors"
require "cultome_player/extras/gesture_analizer"
require "cultome_player/extras/kill_song"
require "cultome_player/extras/taste_analizer"
require "cultome_player/extras/lyric_finder"
require "cultome_player/extras/last_fm"

module CultomePlayer
    module Extras
        include CommandAlias
        include CopyTo
        include Colors
        include GestureAnalizer
        include KillSong
        include TasteAnalizer
        include LyricFinder
        include LastFm

        # Register a callback to the event quitting.
        #
        # @param base [Class] The class where this module was included.
        def self.included(base)
            CultomePlayer::Player.register_event_listener(:quitting, :save_extras_config_file)
        end

        # Persist the global configuration to the player's configuration file.
        def save_extras_config_file
            stored = load_config_file
            merged = stored.merge(extras_config)
            File.open(config_file, 'w'){|f| YAML.dump(merged, f)}
        end

        # Accessor for the persistent configurations hash.
        #
        # @return [Hash] The persistent configurations.
        def extras_config
            @extras_config ||= load_config_file
        end

        private

        # Load the config file from the config_file path.
        #
        # @return [Hash] A hash with the persisted configuration or empty if there is any.
        def load_config_file
            return {} unless File.exist?(config_file)
            config = YAML.load_file(config_file)
            return config if config
            return {}
        end
    end
end
