require 'cultome_player/player/interface'
require 'cultome_player/player/interactive'
require 'cultome_player/player/playlist'
require 'cultome_player/player/adapter'

module CultomePlayer
  module Player
    include Interface
    include Interactive
    include Playlist
    include Adapter
  end
end
