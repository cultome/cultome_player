require 'active_support'

module Cultome
    extend ActiveSupport::Autoload

    autoload :InstallationIntegrity
    autoload :Player, 'cultome/jl_gui_basic_player'
    autoload :CultomePlayer, 'cultome/core'
    autoload :UserInput
    autoload :Helper
    autoload :Plugins
end

