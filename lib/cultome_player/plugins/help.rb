module CultomePlayer
	module Plugins
		module Help

	    def command_help(cmd)
	    	if cmd.params.empty?
	    		success(message: help_cultome_player)
	    	else
	    		help = send("help_#{cmd.params.first.value}")
	    		if help.nil?
	    			failure(message: "No help is available for '#{cmd.first.value}'.")
	    		else
	    			success(message: help)
	    		end
	    	end
	    end

	    def help_help
	    end
		end
	end
end