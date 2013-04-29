
class CultomePlayerException < Exception

	attr_accessor :data
	attr_accessor :type

	def initialize(type=:unknown, data=nil)
		case type
		when :invalid_command
			super("Invalid command. Type typing 'help' for information.")
			@data = data
		else
			super("Something went seriouslly wrong!!")
		end
	end
end
