
class CultomePlayerException < Exception

	# Creates an exception and depending on the parameter __type__, change the message of the exception to a more user-friendly message.
	# The accepted types are:
	#	* :unable_to_play
	#	* :invalid_parameter
	#	* :unable_to_scrobble
	#	* :internet_not_available
	#	* :invalid_command
	#	* :no_active_playback
	#
	# The extended data actually includes:
	#	* displayable (default: true)
	#	* take_action (default: false)
	#	* error_message 
	#	* command 
	#
	#	Except for the first two, that are used by the player to identify when a error should be displayed and do the default error action, respectivly, the others are used as information only.
	#
	# @param type [Symbol] The type of exception
	# @param data [Array] Extended exception information
	def initialize(type=:unknown, *data)
		@data = {
			displayable: true, 
			take_action: false,
		}.merge(data.empty? ? {} : data[0])

		@accesors = []
		@data.each do |k,v|
			create_accessors(k)
		end

		case type
		when :invalid_command then super("Invalid command. Type typing 'help' for information.")
		when :unable_to_play then super("Unable to play.")
		when :invalid_parameter then super("Invalid parameter.")
		when :unable_to_scrobble then super("Can't scrobble if artist or track names are unknown. Edit the ID3 tag.")
		when :internet_not_available then super("Internet is not available!")
		when :no_active_playback then super("There is not active playback")
		else super("Something went seriously wrong!!")
		end
	end

	def respond_to?(value)
		@accesors.include?(value) || value == :exception
	end

	# Create an attribute in the data map with their respective accesors (see #create_accessors).
	#
	# @param attr [Symbol] The name of the attribute to be created
	# @param value [Object] The value of the attribute
	def add_attribute(attr, value)
		@data[attr.to_sym] = value
		create_accessors(attr)
	end

	private

	# Creates three attribute accessor por every attribute: attr, attr= and attr?
	#
	# @param attr [Symbol] The attribute name to generate the accesors
	def create_accessors(attr)
		wr, rd, qt = "#{attr}=".to_sym, "#{attr}".to_sym, "#{attr}?".to_sym
		@accesors << wr << rd << qt

		CultomePlayerException.class_eval do
			define_method wr do |new_value|
				@data[attr] = new_value
			end
			define_method rd do
				@data[attr]
			end
			define_method qt do
				@data[attr]
			end
		end
	end
end
