module CultomePlayer
	module Plugins
		module Gestures
			def init_plugin_gestures
				register_listener(:after_command){|cmd, res| check_gesture(cmd) }
			end

			private

			def actions_history
				@history ||= []
			end

			def check_gesture(cmd)
				if cmd.history?
					actions_history << [cmd, Time.new]
					check_looking_for_something
				end
			end

			def check_looking_for_something
				recents = actions_history.select{|cmd, time| time >= Time.new - 60}
				if recents.count{|cmd, time| cmd.action == "next"} >= 5
					recents.delete_if {|cmd, time| cmd.action == "next"}
					suggest_songs
				end
			end

			def suggest_songs
				display "Can I suggest you something?"
			end

		end
	end
end
