require 'cultome_player/player/interface/basic'
require 'cultome_player/player/interface/extended'
require 'cultome_player/player/interface/helper'
require 'cultome_player/player/interface/builtin_help'

module CultomePlayer::Player
  module Interface
    include Basic
    include Extended
    include Helper
    include BuiltinHelp
  end
end
