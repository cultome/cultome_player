require 'cultome_player/plugins/help'

module CultomePlayer
	module Plugins
		include Help

		def plugins_respond_to?(command)
			# TODO implement
			true
		end

		def plugin_command_format(command)
			# TODO implement
			/^literal (literal)$/
		end
	end
end