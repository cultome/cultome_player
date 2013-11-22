require 'cultome_player/command/language'
require 'cultome_player/command/processor'
require 'cultome_player/command/reader'

module CultomePlayer
  module Command
    include Language
    include Processor
    include Reader
  end
end
