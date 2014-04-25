module CultomePlayer
	module Plugins
		module Points
			def init_plugin_points
				register_listener(:playback_finish)
			end

			def on_playback_finish(song)
				puts "on_playback_finish(#{song.inspect})"
			end
		end
	end
end