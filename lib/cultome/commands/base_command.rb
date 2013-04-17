
# Base class for plugin/commads/listeners that provide common funcionality.
class BaseCommand

	# Get and store a copy of the CultomePlayer instance to operate with.
	#
	# @param player [CultomePlayer] An instance of the player to operate with.
	def initialize(player)
		@p = player
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
