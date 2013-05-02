require 'cultome/plugin'

module Plugin
	class CommandAlias < PluginBase
		# Register this listener for the events: All the throws of player's exceptions events.
		# @note Required method for register listeners
		#
		# @return [List<Symbol>] The name of the events to listen.
		def get_listener_registry
			[:__PLAYER_EXCEPTIONS__]
		end

		# Register the commands: alias
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def get_command_registry
			{
				:alias => {help: "Create an alias for one or many commands", params_format: "<literal> => <literal>"},
			}
		end

		def alias(params=[])
			puts "ALIAS: #{params.inspect}"
		end

		private

		ALIAS = {
			'sa' => 'search @artist',
			'n' => 'next'
		}

		# Invoked when a player exception is throwed
		#
		# @param ex [CultomePlayerException] The exception throwed
		def player_exception_throwed(ex)
			raise ex if ALIAS[ex.data].nil?
			return execute ALIAS[ex.data]
		end
	end
end
