
module Plugins
	module CommandAlias
		# Register this listener for the events: All the throws of player's exceptions events.
		# @note Required method for register listeners
		#
		# @return [List<Symbol>] The name of the events to listen.
		def self.get_listener_registry
			{ player_exception_throwed: :player_exception_throwed}
		end

		# Register the commands: alias
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def self.get_command_registry
			{
				:alias => {
					help: "Create an alias for one or many commands", 
					params_format: "<literal> => <literal>",
					usage: <<HELP
Create a synonimous for a "command string", where "command string" is a valid sequence of commands. The command string can declare placeholder that will be filled with parameters provided by user.

Some usages examples includes the followings:

If you miss Vim you can alias the command quit with the string 'q!'. So the next time you want to close the player just type 'q!'.
	* alias quit => q!

If you are like me, and you like to hear a song that you know when you search it always appears in the same position in the results list, you can make a "macro" to play it. This way you preserve you current playlist and hear you song anytime.
	* alias search_and_play => "search %1 | play %2"
With this little "macro", you are declaring a placeholder that will be replaced with whaterever the user pass as parameter with your alias. For example
	* search_and_play space 2
Will be converted to
	* search space | play 2
You can declared as many place holders as you want. The rules of players' parameters are always presents, so if, for example, space characters exist in the command or command's parameter, this must be wrapped by " or '.

HELP
				}
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

			CommandAlias.aliases[alias_name] = alias_value
		end

		# Invoked when a player exception is throwed
		#
		# @param ex [CultomePlayerException] The exception throwed
		def self.player_exception_throwed(cultome, ex)
			return unless ex.respond_to?(:command)

			# separamos el comando
			split = ex.command.split(' ')
			return if split[0].nil? || CommandAlias.aliases[split[0]].nil?

			translated = CommandAlias.aliases[split[0]].clone

			if split.size > 1
				1.upto(split.size - 1) do |c|
					translated.gsub!(/\%#{c}/, split[c])
				end
			end

			ex.add_attribute(:displayable, false)

			return cultome.execute translated
		end

		def self.aliases
			config["aliases"] ||= {"exit" => "quit"}
		end
	end
end
