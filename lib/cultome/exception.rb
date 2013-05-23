
class CultomePlayerException < Exception

	def initialize(type=:unknown, *data)
		@data = {
			displayable: true, 
			take_action: false,
		}.merge(data.empty? ? {} : data[0])

		case type
		when :invalid_command then super("Invalid command. Type typing 'help' for information.")
		when :unable_to_play then super("Unable to play.")
		when :invalid_parameter then super("Invalid parameter.")
		when :unable_to_scrobble then super(error_message)
		else super("Something went seriously wrong!!")
		end
	end

	def method_missing(method_name, *args)
		stripped_name, punctuation = method_name.to_s.sub(/([?!=])$/, '').to_sym, $1
		return super unless @data[stripped_name]

		CultomePlayerException.class_eval do
			define_method "#{stripped_name}#{punctuation}" do
				@data[stripped_name]
			end
		end

		send method_name
	end

	def respond_to?(value)
		!@data[value].nil? || value == :exception
	end
end
