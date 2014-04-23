module CultomePlayer
	module Plugins
		module Help

	    def command_help(cmd)
	    	if cmd.params.empty?
	    		success(message: help_cultome_player)
	    	else
	    		help = send("usage_#{cmd.params.first.value}")
	    		if help.nil?
	    			failure(message: "No help is available for '#{cmd.first.value}'.")
	    		else
	    			success(message: help)
	    		end
	    	end
	    end

	    def description_help
	    	"Provides information for player features."
	    end

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

    def help_cultome_player
	    cmds_availables = methods.grep(/^description_/).collect do |method_name|
	      [method_name.to_s.gsub("description_", ""), send(method_name)]
	    end

	    border_width = 5
	    cmd_column_width = cmds_availables.reduce(0){|sum, arr| sum > arr[0].length ? sum : arr[0].length}
	    desc_column_width = 90 - border_width - cmd_column_width

	    cmds_availables_formatted = cmds_availables.collect do |arr|
	      "   " + arrange_in_columns(arr, [cmd_column_width, desc_column_width], border_width)
	    end

	    return <<-HELP
usage: <command> [param param ...]

The following commands are availables:
#{cmds_availables_formatted.join("\n")}

The params can be of any of these types:
   criterio     A key:value pair. Only a,b,t are recognized.
   literal      Any valid string. If contains spaces quotes or double quotes are required.
   object       Identifiers preceded with an @.
   number       An integer number.
   path         A string representing a path in filesystem.
   boolean      Can be true, false. Accept some others.
   ip           An IP4 address.

See 'help <command>' for more information on a especific command.

Refer to the README file for a complete user guide.
	    HELP
	  end
		end
	end
end