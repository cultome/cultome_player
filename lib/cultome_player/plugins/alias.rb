module CultomePlayer
	module Plugins
		module Alias

			def command_alias(cmd)
				command = cmd.params.first.value
				aka = cmd.params.last.value
				plugin_config(:alias)[aka] = command
				return success("Alias '#{aka}' created!")
			end

			def respond_to?(name)
				# si no esta buscando commands lo dejamos pasar
				return super unless name =~ /^command_(.+?)$/
				# si el comando existe, lo dejamos pasar
				return true if super
				# aqui podria ser un alias
				aka = $1
				cmd_aliased = plugin_config(:alias)[aka]
				# si no es un alias, lo dejamos pasar
				return false if cmd_aliased.nil?
				# aqui definimos los metodos requeridos para el alias
				# alias execution...
				self.class.send(:define_method, "command_#{aka}".to_sym) do |cmd|
					prepared_command = cmd_aliased.clone
					# we replace parameters
					cmd.params_values(:literal).each.with_index do |p, idx|
						prepared_command.gsub!(/%#{idx + 1}/, "'#{p}'") # TODO aqui manejar los parametros con quotes
					end
					# execute the alias
					return execute(prepared_command)
				end
				# ...and sintaxis
				self.class.send(:define_method, "sintaxis_#{aka}".to_sym) do
					return /^literal(literal|[\s]+)*$/ # devolvemos la sintaxis para la invocacion del alias, no del comando
				end
				## devolvemos exito
				return true
			end

			def sintaxis_alias
				/^literal (literal) bubble (literal) $/
			end

			def description_alias
				"Create an alias for a command."
			end

			def usage_alias
				return <<-USAGE
usage: alias command => alias

Creates an alias for a command. Similar to what the bash do.
Can receive parameters in form of %<number>, eg %1, %2, %3... These parameters are passed when the alias is called.

Examples:

Create an alias to always play the first result in a search:
	alias "search %1 && play 1" => s

And you would call it like
	s metallica

				USAGE
			end
		end
	end
end