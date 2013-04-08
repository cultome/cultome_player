
class GestureAnalizer
	def initialize
		@queue = EventQueue.new
	end

	def add_command(cmd)
		@queue.add_event(cmd)
		analize_queue
	end

	def analize_queue
		# checamos el patron y vemos si matchea
		if @queue.has(5, 'next', 20)
			puts "#### Notifying: Looking for something"
		end
	end
end

class EventQueue
	def initialize
		@events = []
	end

	def add_event(cmd)
		cmd[:time] = Time.new
		cmd[:used] = false

		@events.push(cmd)
	end

	def has(event_count, event, within_time=0)
		evts = @events.select{|e| e[:command] == event && !e[:used]}
		if evts.size >= event_count
			consume = true

			if within_time > 0
				latest = evts.max{|a,b| a[:time] <=> b[:time] }
				oldest = evts.min{|a,b| a[:time] <=> b[:time] }

				consume = latest[:time] - oldest[:time] <= within_time
			end

			@events.each{|e| e[:used] = true if e[:command] == event } if consume

			return consume
		end

		return false
	end
end
