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
			if get_confirmation("Are you sure you want to delete #{@p.song} ???")
				# detenemos la reproduccion
				@p.execute('stop')

				path = Shellwords.escape("#{@p.song.drive.path}/#{@p.song.relative_path}")
				system("mv #{path} ~/tmp/#{rand()}.mp3")

				if $?.exitstatus == 0
					@p.song.delete
					display("Song deleted!")
				else
					display("An error occurred when deleting the song #{@p.song}")
				end

				# reanudamos la reproduccion
				@p.execute('next')
			end
		end
	end
end
