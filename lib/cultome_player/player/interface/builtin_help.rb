module CultomePlayer
  module Player
  	module BuiltinHelp
  		def description_play
  			"Creates a playlist and start playing. Resumes playback."
  		end

			def description_pause
				"Toggle pause."
			end

			def description_stop
				"Stops current playback."
			end

			def description_next
				"Play the next song in current playlist."
			end

			def description_prev
				"Play the last song in history playlist."
			end

			def description_quit
				"Quits the playback and exit the player."
			end

			def description_search
				"Search into the connected music drives."
			end

			def description_show
				"Shows representations of diverse objects in the player."
			end

			def description_enqueue
				"Append a playlist to the queue playlist."
			end

			def description_shuffle
				"Check the state of shuffle. Can turn it on and off."
			end

			def description_connect
				"Add or reconnect a drive to the music library."
			end

			def description_disconnect
				"Disconnect a drive from the music library."
			end

			def description_ff
				"Fast forward 10 seconds the current playback."
			end

			def description_fb
				"Fast backward 10 seconds the current playback."
			end

			def description_repeat
				"Repeat the current playback from the begining."
			end

  	end
  end
end