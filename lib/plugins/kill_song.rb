require 'cultome/plugin'
require 'cultome/user_input'
require 'cultome/persistence'
require 'shellwords'

module Plugin
	class KillSong < PluginBase

		include UserInput

		# Register the commands: kill.
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def get_command_registry
			{
				kill: {help: "Delete from disk the current song", params_format: ""}
			}
		end

		# Remove the current song from library and from filesystem.
		def kill(params=[])
			if get_confirmation("Are you sure you want to delete #{@cultome.song} ???")
				# detenemos la reproduccion
				@cultome.execute('stop')

				path = Shellwords.escape("#{@cultome.song.drive.path}/#{@cultome.song.relative_path}")
				system("rm #{path}")

				if $?.exitstatus == 0
					@cultome.song.delete
					display("Song deleted!")
				else
					display("An error occurred when deleting the song #{@cultome.song}")
				end

				# reanudamos la reproduccion
				@cultome.execute('next')
			end
		end
	end
end
