module CultomePlayer
	module Plugins
		module Help

			# Command implementation for action "help".
			# Shows usage information for the actions of the player if called with an action as parameter and shows a player usage information if called without parameters.
			#
			# @contract Plugin
			# @param cmd [Command] Command information parsed from user input
			# @return [Response] Contains a message to be displayed with the help required.
	    def command_help(cmd)
	    	if cmd.params.empty?
	    		success(message: usage_cultome_player)
	    	else
	    		help = send("usage_#{cmd.params.first.value}")
	    		if help.nil?
	    			failure(message: "No help is available for '#{cmd.first.value}'.")
	    		else
	    			success(message: help)
	    		end
	    	end
	    end

	    # Description of the action help.
	    #
	    # @contract Help Plugin.
	    # @return [String] The description of the action.
	    def description_help
	    	"Provides information for player features."
	    end

			# Usage information of the action help.
	    #
	    # @contract Help Plugin.
	    # @return [String] The usage information of the action.
	    def usage_help
	    	return <<-USAGE
usage: help [command]

Provides usage information for player commands. If called without parameters, shows the player usage.

Examples:

To see all the commands availables in the player:
	help

To see the usage for play command:
	help play

	    	USAGE
	    end
		end
	end
end