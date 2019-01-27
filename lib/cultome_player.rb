require "cultome_player/version"

module CultomePlayer
  class Error < StandardError; end
end

require "cultome_player/config"
require "cultome_player/utils"
require "cultome_player/events"
require "cultome_player/core"

module CultomePlayer
  include Config
  include Utils
  include Events
  include Core
end
