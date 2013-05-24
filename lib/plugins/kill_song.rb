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
				kill: {
					help: "Delete from disk the current song", 
					params_format: "",
					usage: <<HELP
Have you ever downloaded a full record of a new artist to "hear something new"? Maybe not all songs are good enough to be kepped in you collection. So while you're
listening the song and think "mmmmm not for me", just type
	* kill
The player ask you a confirmation of the deletion and there you are! the song is gone forever.

HELP
			}}
		end

		# Remove the current song from library and from filesystem.
		def kill(params=[])
			raise CultomePlayerException.new(:no_active_playback, take_action: false) if @cultome.song.nil?

			if get_confirmation("Are you sure you want to delete #{@cultome.song} ???")
				# detenemos la reproduccion
				@cultome.execute('stop')

				File.delete(File.join(@cultome.song.drive.path, @cultome.song.relative_path))

				if $?.exitstatus == 0
					@cultome.song.delete
					display c4("Song deleted!")
				else
					display c2("An error occurred when deleting the song #{@cultome.song}")
				end

				# reanudamos la reproduccion
				@cultome.execute('next')
			end
		end
	end
end
