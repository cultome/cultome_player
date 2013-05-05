
# Base module for plugin/commads/listeners that provide common funcionality.
module Plugin
	class PluginBase
		# Get and store a copy of the CultomePlayer instance to operate with.
		#
		# @param player [CultomePlayer] An instance of the player to operate with.
		def initialize(player, config)
			@p = player
			@config = config
		end

		# A shortcut for the CultomePlayer#display method.
		#
		# @param msg [Object] Any object that responds to #to_s.
		# @param continuos [Boolean] If false a new line character is appended at the end of message.
		# @return [String] The message printed.
		def display(msg, continuos=false)
			@p.display(msg, continuos)
		end
	end
end
