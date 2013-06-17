require "cultome_player/version"
require "cultome_player/socket_adapter"
require "cultome_player/player"
require "cultome_player/user_input"
require "cultome_player/model"
require "cultome_player/external_player"
require "cultome_player/helper"
require 'cultome_player/class_utils'
require 'cultome_player/interactive'
require 'cultome_player/installation_integrity'
require 'cultome_player/extras'
require 'cultome_player/error_handler'

module CultomePlayer
    include SocketAdapter
    include Player
    include UserInput
    include ExternalPlayer
    include Helper
    include Interactive
    include InstallationIntegrity
    include Extras
    include ErrorHandler

end
