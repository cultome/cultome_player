module CultomePlayer
	module Plugins
		module Points
			def init_plugin_points
				register_listener(:playback_finish){|song| on_playback_finish(song) }
				register_listener(:before_command_next){|cmd, res| on_before_change(cmd) }
				register_listener(:before_command_prev){|cmd, res| on_before_change(cmd) }
				register_listener(:after_command_prev){|cmd, res| on_after_prev(cmd, res) }
			end

			private

			def on_before_change(cmd)
				return if current_song.nil?

				percent_played = playback_length * playback_position / 100
				# current_song => the old song
				case percent_played
					when (10..50) then current_song.update(points: current_song.points - 1)
					when (81..100) then current_song.update(points: current_song.points + 1)
				end
			end

			def on_after_prev(cmd, response)
				return if current_song.nil?

				if response.success?
					current_song.update(points: current_song.points + 1) # # current_song => the new song
				end
			end

			def on_playback_finish(song)
				song.update(points: song.points + 1)
			end
		end
	end
end