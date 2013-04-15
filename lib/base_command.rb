
class BaseCommand
	def initialize(player)
		@p = player
	end

	def display(msg, continuos=false)
		@p.display(msg, continuos)
	end
end
