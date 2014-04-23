require 'cultome_player/plugins/help'

module CultomePlayer
	module Plugins
		include Help

		# Check if a plugin implements the given command.
		#
		# @param command [String] The command name.
		# @return [Boolean] True is the given command is implemented by a plugin.
		def plugins_respond_to?(command)
			# TODO implement
			true
		end

		# Get a command format for a command implemented by a plugin
		#
		# @param command [String] The command name.
		# @return [Regex] The regex to validate a command format that is implemented by a plugin.
		def plugin_command_format(command)
			# TODO implement
			/^literal (literal)$/
		end
	end
end