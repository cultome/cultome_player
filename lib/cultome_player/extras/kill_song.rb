require 'shellwords'

module CultomePlayer::Extras
    module KillSong

        # Register the commands: kill.
        # @note Required method for register commands
        #
        # @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
        def self.included(base)
            CultomePlayer::Player.command_registry << :kill
            CultomePlayer::Player.command_help_registry[:kill] = {
                help: "Delete from disk the current song", 
                params_format: "",
                usage: <<-HELP
Have you ever downloaded a full record of a new artist to "hear something new"? Maybe not all songs are good enough to be kepped in you collection. So while you're
listening the song and think "mmmmm not for me", just type
    * kill
The player ask you a confirmation of the deletion and there you are! the song is gone forever.

                HELP
            }
        end

        # Remove the current song from library and from filesystem.
        def kill(params=[])
            raise 'no active playback' if current_song.nil?

            if get_confirmation("Are you sure you want to delete #{current_song} ???")
                # detenemos la reproduccion
                stop

                File.delete(File.join(current_song.drive.path, current_song.relative_path))

                if $?.exitstatus == 0
                    current_song.delete
                    display c4("Song deleted!")
                else
                    display c2("An error occurred when deleting the song #{current_song}")
                end

                # reanudamos la reproduccion
                self.next
            end
        end
    end
end
