require 'cultome_player/player/interface/basic'
require 'cultome_player/player/interface/extended'
require 'cultome_player/player/interface/helper'

module CultomePlayer::Player
  module Interface
    include Basic
    include Extended
    include Helper
  end
end
