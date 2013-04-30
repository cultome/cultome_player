
# Base module for plugin/commads/listeners that provide common funcionality.
module Plugin
	class PluginBase
		# Get and store a copy of the CultomePlayer instance to operate with.
		#
		# @param player [CultomePlayer] An instance of the player to operate with.
		def initialize(player)
			@p = player
		end

		# A shortcut for the CultomePlayer#display method.
		#
		# @param msg [Object] Any object that responds to #to_s.
		# @param continuos [Boolean] If false a new line character is appended at the end of message.
		# @return [String] The message printed.
		def display(msg, continuos=false)
			@p.display(msg, continuos)
		end

		def method_missing(method_name, *args)
			if @p.instance_variables.grep(/@#{method_name}/).empty?
				# podria ser un metodo...
				# si no lo es, tira una exception
				return super unless @p.respond_to?(method_name)

				self.class.class_eval do
					define_method method_name do
						@p.send(method_name, param)
					end
				end

				return send(method_name, *args)
			else
				# es una variable
				self.class.class_eval do
					define_method method_name do
						@p.instance_variable_get("@#{method_name}")
					end
				end

				return @p.instance_variable_get("@#{method_name}")
			end
		end

		def respond_to?(method)
			@p.respond_to?( method ) || super
		end
	end
end
