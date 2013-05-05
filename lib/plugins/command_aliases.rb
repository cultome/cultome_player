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

		# Create a persistent alias.
		#
		# @param params [List<Hash>] With parsed literals information.
		def alias(params=[])
			return nil if params.size != 2
			return nil unless params.all?{|a| a[:type] == :literal || a[:type] == :unknown }

			alias_name = params[0][:value]
			alias_value = params[1][:value]

			aliases[alias_name] = alias_value
		end

		private

		# Invoked when a player exception is throwed
		#
		# @param ex [CultomePlayerException] The exception throwed
		def player_exception_throwed(ex)
			# separamos el comando
			split = ex.data.split(' ')
			raise ex if split[0].nil? || aliases[split[0]].nil?

			translated = aliases[split[0]]

			if split.size > 1
				1.upto(split.size - 1) do |c|
					translated.gsub!(/\%#{c}/, split[c])
				end
			end

			return @cultome.execute translated
		end

		def aliases
			@config["aliases"] ||= {"exit" => "quit"}
		end
	end
end
