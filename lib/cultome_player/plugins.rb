require 'cultome_player/plugins/help'

module CultomePlayer
	module Plugins
		include Help

		# Check if a plugin implements the given command.
		#
		# @param cmd_name [String] The command name.
		# @return [Boolean] True is the given command is implemented by a plugin.
		def plugins_respond_to?(cmd_name)
			return respond_to?("command_#{cmd_name}".to_sym)
		end

		# Get a command format for a command implemented by a plugin
		#
		# @param cmd_name [String] The command name.
		# @return [Regex] The regex to validate a command format that is implemented by a plugin.
		def plugin_command_sintaxis(cmd_name)
			return send("sintaxis_#{cmd_name}".to_sym)
		end
	end
end